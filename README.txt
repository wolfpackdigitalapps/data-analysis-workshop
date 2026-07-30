Data Analysis Workshop — deploy bundle (Wolfpack Digital)
=========================================================
Contents: index.html (hub) · nimbus-app.html (mock app; add ?facilitator=1 for the
facilitator panel) · nimbus-analytics.html (Mixpanel-style analytics) ·
workshop-deck.html (49-slide facilitation deck, section timers, QR codes,
per-exercise deep links) · exercise-workbook.html (guided multi-page workbook) ·
initiative-tracker.html (web tracker, multi-group, auto-ICE, coverage check) ·
nimbus-client-deck.html (model answer) · facilitator-rubric.html ·
nimbus-initiative-tracker.xlsx · LICENSE (CC BY-NC-SA 4.0) · .nojekyll

To publish or update GitHub Pages:
  1) Make sure GitHub CLI is authed:  gh auth status
  2) From this folder run:            ./deploy.sh
Everything is static — no build step, no server.
