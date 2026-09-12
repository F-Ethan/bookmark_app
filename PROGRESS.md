# Progress

Working notes for Bookmark. Agents must record anything discovered but left unfixed under **Known gaps**.

## Known gaps

- **README is stale.** It still describes a SharedPreferences-only, iOS-only tracker. The app now has Supabase auth, guest mode, an in-app reader, book-group editing, verse highlights, optional BBE download, and appearance settings.
- **`test/widget_test.dart` does not match the app.** It constructs `MyApp(isFirstTime: …)`, which no longer exists, and expects routes/copy that predate `go_router` + auth. It is not a reliable launch test.
- **`dart_defines/dev.json` is required for local `--dart-define-from-file` launches and is gitignored.** The file is not in the repo; new machines need a local copy. Do not commit it.
- **Chapter-read ticks are device-local only** (`chapter_read_day_*` in SharedPreferences), including for signed-in users. They do not sync across devices.
- **Guest data is not migrated on sign-up.** Creating an account after guest use does not copy the local plan, groups, or highlights into Supabase.
- **README roadmap vs code.** Android embeddings, local notifications, and in-app Bible text already exist in some form. Export (PDF/CSV), audio, and a home-screen widget are still absent. Screenshots are still marked "still to come."
- **No `LICENSE` file**, though the README claims MIT.

## In scope for this change

- Agent working rules (`CLAUDE.md`) and this progress file.
