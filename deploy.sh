#!/usr/bin/env bash
# Deploy / update the Data Analysis Workshop on GitHub Pages (org: wolfpackdigitalapps)
# Usage: ./deploy.sh   (run from this folder; needs gh CLI authed + git)
set -euo pipefail
ORG="wolfpackdigitalapps"
REPO="data-analysis-workshop"
echo "==> Deploying to https://github.com/$ORG/$REPO (GitHub Pages)"
if ! gh repo view "$ORG/$REPO" >/dev/null 2>&1; then
  echo "==> Repo doesn't exist yet — creating it (public)"
  gh repo create "$ORG/$REPO" --public --description "Data Analysis Workshop — Wolfpack Digital (Nimbus demo kit)" >/dev/null
fi
if [ ! -d .git ]; then git init -q -b main; fi

# macOS drops a .DS_Store into any folder you so much as look at in Finder, and
# .gitignore lists it -- but the manifest check below walks the folder with find,
# which does not consult .gitignore. Without this sweep, opening the folder to
# check the files are there is enough to make the next deploy refuse with a
# message about an unrecognised file. Swept, not whitelisted: these should never
# reach the repo either.
# .git is pruned rather than trusted to contain no matches: -delete inside an
# object store is not a mistake worth risking to save one predicate.
find . -not -path './.git/*' \( -name '.DS_Store' -o -name '._*' \) -delete 2>/dev/null || true

# --- pre-flight: this script force-pushes whatever is in this folder ----------
# "git add -A" plus "push --force" means one stray file becomes a permanent part
# of a public repo's history. That is not hypothetical: a preview run writes its
# screenshots into ./pv2, and a build that ran from here once put 7MB of PNGs
# into the archive before anyone noticed. So the folder is checked against a
# manifest first, and anything unrecognised stops the deploy rather than riding
# along with it. Adding a file on purpose? List it here, or run with
# DEPLOY_ALLOW_EXTRA=1 for a one-off.
EXPECTED="index.html workshop-deck.html nimbus-client-deck.html nimbus-analytics.html
nimbus-app.html exercise-workbook.html facilitator-rubric.html initiative-tracker.html
nimbus-initiative-tracker.xlsx README.txt LICENSE deploy.sh .nojekyll .gitignore"
# Collapse the newlines above into single spaces before matching -- the test is
# case "$EXPECTED" in *" $f "*, so a name sitting at a line break is bounded by
# a newline instead of a space and silently fails to match. Four of the nine
# artifacts did exactly that on the first run of this guard.
EXPECTED=" $(printf '%s' "$EXPECTED" | tr -s '[:space:]' ' ') "
extra=""
while IFS= read -r f; do
  f="${f#./}"
  case "$EXPECTED" in *" $f "*) ;; *) extra="$extra  $f
";; esac
done < <(find . -mindepth 1 -not -path './.git' -not -path './.git/*' -print)
if [ -n "$extra" ] && [ "${DEPLOY_ALLOW_EXTRA:-0}" != "1" ]; then
  echo ""
  echo "✋ Refusing to deploy — these are in the folder but not on the manifest:"
  printf '%s' "$extra"
  echo ""
  echo "   Delete them, add them to EXPECTED in this script, or re-run as:"
  echo "     DEPLOY_ALLOW_EXTRA=1 ./deploy.sh"
  exit 1
fi

# The check above is a whitelist, and a whitelist is blind to absence: a folder
# with eleven of the twelve pages passes it perfectly and publishes a kit with a
# dead link in the middle of it. Downloading files one at a time is exactly how
# you end up one short, so the manifest is also read as a checklist.
missing=""
for f in $EXPECTED; do
  [ -e "$f" ] || missing="$missing  $f
"
done
if [ -n "$missing" ]; then
  echo ""
  echo "✋ Refusing to deploy — the manifest lists these, and they are not here:"
  printf '%s' "$missing"
  echo ""
  echo "   Deploying now would publish a kit with dead links in it. Fetch the"
  echo "   missing files into this folder and run again."
  exit 1
fi

git add -A
git commit -q -m "Update workshop kit $(date +%Y-%m-%d_%H%M)" || echo "(nothing new to commit)"
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$ORG/$REPO.git"
git push -q --force origin main
# Enable Pages from main / root (no-op if already enabled)
gh api -X POST "repos/$ORG/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || \
gh api -X PUT  "repos/$ORG/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || true
echo ""
echo "✅ Pushed. GitHub Pages will refresh in ~1–2 minutes."
echo "   Hub:        https://$ORG.github.io/$REPO/"
echo "   App:        https://$ORG.github.io/$REPO/nimbus-app.html   (facilitator view: ?facilitator=1)"
echo "   Analytics:  https://$ORG.github.io/$REPO/nimbus-analytics.html"
echo "   Deck:       https://$ORG.github.io/$REPO/workshop-deck.html"
echo "   Workbook:   https://$ORG.github.io/$REPO/exercise-workbook.html"
echo "   Tracker:    https://$ORG.github.io/$REPO/initiative-tracker.html   (facilitator prefill: ?facilitator=1)"
