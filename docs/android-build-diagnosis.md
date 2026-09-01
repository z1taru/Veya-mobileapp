# Android debug build diagnosis

Checked on 2026-09-01 with Flutter 3.47.0.

## Results

- The original silent wait was the first Gradle wrapper download. The verbose
  transcript is retained locally at `build/android-build-verbose.log` (build
  artifacts are intentionally git-ignored).
- The wrapper was changed from the 235 MB `gradle-9.3.1-all.zip` distribution to
  `gradle-9.3.1-bin.zip`. `./gradlew --no-daemon --version` then completed.
- A no-daemon `assembleDebug` advanced through Gradle, AGP, and Kotlin artifact
  downloads. This rules out a Gradle daemon deadlock.
- Android Studio JBR 21.0.10 is compatible with AGP 9.1.0 and Gradle 9.3.1.
- The remaining blocker is an incomplete first install of NDK 28.2.13676358.
  Its SDK directory currently contains `.installer` but no `source.properties`.
  Flutter's `jni` plugin requests that NDK, so pinning the app module to the
  already installed NDK 27 does not solve the build and was reverted.
- `flutter build ios --simulator --debug` succeeds, confirming that the Dart
  code and shared Flutter plugin graph compile outside Android.

## Open item

Complete the SDK Manager installation of NDK 28.2.13676358, then run:

```bash
flutter build apk --debug
```

If installation still stalls, inspect proxy/firewall access to Google's Android
SDK repositories and rerun `sdkmanager --install "ndk;28.2.13676358"` with
verbose output.
