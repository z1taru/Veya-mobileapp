# Veya mobile

Flutter client for family tasks, reminders, shopping lists, and notifications.

## Run

The environment and API URL are compile-time values:

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://localhost:8080
```

For an Android emulator, use `http://10.0.2.2:8080` when the backend runs on
the host machine.

Supported environment names are `dev`, `staging`, and `prod`. No secrets are
stored in dart-defines.

## Generated code

After changing Drift tables, run:

```bash
flutter pub run build_runner build
```

## Current data sources

- Authentication and family membership use the Veya REST API.
- Tasks are offline-first and currently live in Drift. The repository boundary
  is ready to receive a remote sync implementation when the target endpoints
  become available.
- Pull-to-refresh updates the family cache; task mutations update the reactive
  local list immediately.

## Firebase

Firebase packages and the bootstrap boundary are present, but initialization is
disabled until platform configuration files and generated `FirebaseOptions` are
added. Do not commit production Firebase secrets outside the standard platform
configuration flow.

## Backend contract

The mobile-first target contract is documented in
[`docs/backend-target-contract.md`](docs/backend-target-contract.md). The current
backend implements only the auth-compatible subset.
