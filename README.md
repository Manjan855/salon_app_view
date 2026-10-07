# salon_app_view

A new Flutter project.

## Running

Supabase credentials are injected at build time — they are **not** in the
source. First-time setup:

```sh
copy config\supabase.example.json config\supabase.json   # then fill in real values
```

Then always run with the config file:

```sh
flutter run --dart-define-from-file=config/supabase.json
```

VS Code: use the "Flutter (dev, Supabase config)" launch config (F5).

Release builds:

```sh
flutter build apk --dart-define-from-file=config/supabase.json
```

If you forget the flag the app throws a clear `StateError` instead of failing
with a cryptic 401.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
