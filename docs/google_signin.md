# Google Sign-In setup (Android + iOS)

`AuthProvider.loginWithGoogle()` uses the native Google flow
(`google_sign_in` 7.x → `signInWithIdToken`). There is **no
`google-services.json`** in this project, so the *web* OAuth client ID is passed
as the `serverClientId` at runtime — and that value now comes from
`config/supabase.json`, never from source.

| Value | Where it lives | Used for |
|---|---|---|
| Web client ID | `config/supabase.json` → `GOOGLE_SERVER_CLIENT_ID` | Android `serverClientId`; iOS `GIDServerClientID`; Supabase Google provider |
| iOS client ID | `config/supabase.json` → `GOOGLE_IOS_CLIENT_ID` | iOS `GIDClientID` + reversed URL scheme |
| Android package + SHA-1 | Google Cloud Console | proves the Android app is yours |
| iOS bundle ID | Google Cloud Console | proves the iOS app is yours |

App identifiers this project registers:

- Android package / namespace: **`com.salon.salon_app_view`**
  (`android/app/build.gradle.kts`)
- iOS bundle id: **`com.salon.salonAppView`**
  (`ios/Runner.xcodeproj/project.pbxproj`)

> The placeholder `com.example.*` ids have been swapped for `com.salon.*`. If
> you rename them again, register the new package / bundle id in Google Cloud
> Console to match, or Google sign-in breaks with `clientConfigurationError`.

---

## 1. Create the OAuth clients (Google Cloud Console)

Open <https://console.cloud.google.com/apis/credentials> → **Create credentials**
→ **OAuth client ID**. Create all three:

### a. Android
- Type: **Android**
- Package name: `com.salon.salon_app_view`
- SHA-1: your keystore fingerprint (see below) — add **one per build type**.

Get the SHA-1:

```sh
cd android
./gradlew signingReport        # Windows: gradlew.bat signingReport
```

Copy every `SHA1:` line. Add the **debug** keystore now and the **release**
keystore before shipping (a release build with an unregistered SHA-1 fails with
a `clientConfigurationError` / spurious `canceled`).

### b. iOS
- Type: **iOS**
- Bundle ID: `com.salon.salonAppView`

The client ID it gives you is `…apps.googleusercontent.com`. This is the
**iOS client ID**.

### c. Web
- Type: **Web application**
- Authorized redirect URI: `https://zhnfhkahspsqbfjetwlt.supabase.co/auth/v1/callback`

Its client ID is the **web client ID** (this is the important one — it is used
by Android, iOS and Supabase).

> **All three clients must live in the same Google Cloud project.** An Android
> client created in a different project than the web client fails with
> `[28444] developer console is not set up correctly` even when the package name
> and SHA-1 are correct. The project number is the digits before the first `-`
> in the web client ID (e.g. `940621050374-…` → project `940621050374`).

---

## 2. Put the values in the local config

`config/supabase.json` is gitignored. Add the two keys (see
`config/supabase.example.json`):

```json
{
  "SUPABASE_URL": "https://zhnfhkahspsqbfjetwlt.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_…",
  "GOOGLE_SERVER_CLIENT_ID": "…-….apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID": "…-….apps.googleusercontent.com"
}
```

`AppEnv.googleServerClientId` reads `GOOGLE_SERVER_CLIENT_ID`;
`AppEnv.hasGoogleServerClientId` guards the sign-in call so a build without it
fails with a clear message instead of a cryptic plugin error.

---

## 3. iOS `Info.plist`

The iOS plugin **requires** `GIDClientID` and the reversed-client-id URL scheme,
even when the client ID is also passed in Dart. `ios/Runner/Info.plist` already
contains a commented, ready-to-edit block — remove the `<!--` / `-->` and fill in
the values:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- keep the existing salonappview entry … -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- = "com.googleusercontent.apps." + iOS client id before
                 ".apps.googleusercontent.com" -->
            <string>com.googleusercontent.apps.REPLACE_WITH_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<string>REPLACE_WITH_IOS_CLIENT_ID.apps.googleusercontent.com</string>
<key>GIDServerClientID</key>
<string>REPLACE_WITH_WEB_CLIENT_ID.apps.googleusercontent.com</string>
```

Example: for an iOS client ID
`861823949799-vc35cprkp249096uujjn0vvnmcvjppkn.apps.googleusercontent.com`,
the reversed scheme is
`com.googleusercontent.apps.861823949799-vc35cprkp249096uujjn0vvnmcvjppkn`.

## 3b. Android — no manifest change

With `google_sign_in` 7.x and no `google-services.json`, nothing is added to
`AndroidManifest.xml`: the plugin reads the web client ID from the
`serverClientId` argument (already wired in `AuthProvider`). The old
`default_web_client_id` meta-data is **not** used here.

---

## 4. Enable Google in Supabase Auth

Dashboard → **Authentication → Providers → Google**: switch it on and paste the
**web client ID** and its **client secret** (from step 1c). `signInWithIdToken`
validates the ID token's audience against this provider, so it must be the same
web client.

---

## 5. Verify

```sh
flutter run --dart-define-from-file=config/supabase.json
```

- Tap **Continue with Google**, pick an account → the app should return signed
  in (no `clientConfigurationError`, no spurious `canceled`).
- The guard test runs with the flag too:

  ```sh
  flutter test test/google_signin_test.dart \
    --dart-define-from-file=config/supabase.json
  ```

  Without the flag the plist cross-check is skipped and a plain `flutter test`
  stays green.

### Troubleshooting

Run `bash tool/google_signin_check.sh` first — it prints this build's Android
package name, debug SHA-1, the injected client IDs, whether Supabase has Google
enabled, and the exact values to register in Google Cloud Console.

| Symptom | Cause |
|---|---|
| "an unexpected error occurred" right after picking an account | the old, generic catch-all; the reason is now surfaced (row below) |
| app: *"Google Sign-In is misconfigured for this app: the Android package name + SHA-1 …"* / log: `GoogleSignInExceptionCode.clientConfigurationError` | wrong package/bundle id, or SHA-1 not registered — the classic fallout of renaming the app id (`com.example.*` → `com.salon.*`) |
| app/log: `[28444] developer console is not set up correctly` | exactly the same root cause — Google found **no Android OAuth client** for this package + SHA-1, or the Android client lives in a **different Google Cloud project** than the web client used as `serverClientId` |
| unexpected `canceled` right after picking an account | usually the same config error (Credential Manager masks it) |
| works in debug, fails in release | release keystore SHA-1 not registered |
| `Google Sign-In is not configured on this build` | `GOOGLE_SERVER_CLIENT_ID` missing from the dart-define file |
| `Missing security tokens from Google Authentication.` | the web client id was not honoured as `serverClientId` — check `config/supabase.json` |

> **"\<package\> and SHA-1 already exist" when creating the Android client?**
> That means an Android client with those exact values is already registered — in
> whichever project is selected. Don't create a duplicate. Instead confirm:
>
> 1. the selected project number equals the one in the web client ID
>    (`940621050374` in this project), and
> 2. that existing Android client's package is `com.salon.salon_app_view` and its
>    SHA-1 matches `tool/google_signin_check.sh`.
>
> If both are right, `[28444]` is usually just cached per app by Google Play
> services: force-stop the app, clear **Google Play services** cache
> (Settings → Apps → Google Play services → Storage → Clear cache), uninstall +
> reinstall the app, and give Google a few minutes to propagate a new client.
