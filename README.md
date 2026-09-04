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

## Running on a physical iPhone

1. Connect the iPhone to the Mac with a cable, unlock it, and confirm **Trust
   This Computer** on the iPhone if prompted.
2. If iOS requires it, enable **Developer Mode** in **Settings > Privacy &
   Security > Developer Mode**, then restart and confirm the setting.
3. Confirm that Flutter detects the device:

   ```bash
   flutter devices
   ```

4. Open `ios/Runner.xcworkspace` in Xcode. In the Runner target's **Signing &
   Capabilities** settings, select your Apple Development Team and set a Bundle
   Identifier that is unique to your Apple developer account. Do not add a
   personal Team ID to this repository.
5. With the Mac and iPhone on the same Wi-Fi network, start the backend so it
   accepts connections from the local network. Allow incoming connections for
   the backend through the macOS firewall, then run the app with the existing
   dart-defines and the Mac's local IP address:

   ```bash
   flutter run \
     --dart-define=APP_ENV=dev \
     --dart-define=API_BASE_URL=http://<MAC_LOCAL_IP>:8080
   ```

   On a physical iPhone, `localhost` refers to the iPhone itself, not the Mac,
   so it cannot reach a backend running on the Mac. Use the Mac's local IP
   address instead.

Never commit private keys, provisioning profiles, passwords, `.env` files,
signing certificates, or other credentials to Git.

## Generated code

After changing Drift tables, run:

```bash
flutter pub run build_runner build
```

## Current data sources

- Authentication and family membership use the Veya REST API.
- Tasks, comments, reminders, attachment queue metadata, named shopping lists,
  checklist items, and activity events are offline-first and live in Drift.
  Their repository boundaries are ready for remote sync implementations when
  the target endpoints become available.
- Pull-to-refresh updates the family cache; task mutations update the reactive
  local list immediately.
- Picked attachment files are copied into application support storage and kept
  with a client-only state of `QUEUED`, `UPLOADING`, `UPLOADED`, or `FAILED`.
  The remote uploader is deliberately deferred until the backend multipart
  endpoint is available.

## Firebase

Firebase packages and the bootstrap boundary are present, but initialization is
disabled until platform configuration files and generated `FirebaseOptions` are
added. Do not commit production Firebase secrets outside the standard platform
configuration flow.

## Backend contract

The mobile-first target contract is documented in
[`docs/backend-target-contract.md`](docs/backend-target-contract.md). The current
backend implements only the auth-compatible subset.
