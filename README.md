# ItFollows
It Follows: Sync Notes

Purpose / use case:
Self-hosted synced notes, single list sorted by most recent descending. That's it.

Features (General):
- List of notes, to be viewed in webbrowser or app (android)
- Browser: add note, delete note, delete all notes

Features (Android):
- Fetch notes from server (api endpoint via settings in app), store offline copy
- Add notes, copy notes, delete notes
- Incoming share intent
- Open browsers from within app

Future plans:
- iOS support
- App: Authentication and/or light encryption
- App: Offline handling: save note and sync when online

Not implemented and not planned:
- Strong security or privacy; don't store your missile launch codes via ItFollows
- Sophisticated UI / multiple lists or portfolios

Developer notes:
See ./server for webserver stuff (php).
Built with Flutter (Dart) for Android target: flutter build apk --split-per-abi
