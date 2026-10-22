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
package name, the debug keystore SHA-1, the injected client IDs, whether Supabase
has Google enabled, and — most importantly — **the SHA-1 and client ID actually
baked into `app-debug.apk`**, with a MATCH/DIFFERS verdict. That is the only
check that reflects what the device really installs; reading the keystore file
alone can disagree with the APK if the build is stale or signed by another key.

#### Why `[28444]` keeps coming back

`[28444] "developer console is not set up correctly"` is emitted by Google Play
services / Credential Manager, not by this app. Google looks up an **Android**
OAuth client whose `(package name, SHA-1)` matches the installed APK, inside the
**same project as the `serverClientId` web client**, and rejects the request if
it cannot find an exact match. "Exact match" is stricter than it looks:

1. **Same project.** A client with the right package + SHA-1 in *another*
   project never matches. The project number is the digits before the first `-`
   of the web client ID (`940621050374-…` → project `940621050374`).
2. **Globally unique pair.** Google allows a `(package, SHA-1)` pair in exactly
   one Firebase/Google Cloud project, ever. If the pair your APK signs with is
   already owned by another project, you cannot re-create it in the right one —
   you must free it or mint a new SHA-1 (below).
3. **The installed APK is the yardstick.** `flutter run`, a sideloaded
   `app-debug.apk`, and a Play-signed build are three different signatures.
   Register the one you actually test with.
4. **Propagation takes time.** Google documents that OAuth client changes can
   take **up to a few hours** to take effect. A "still failing right after I
   fixed it" is often just this window, compounded by Play services caching the
   failure per app.
5. **Consent screen.** With the app in **Testing**, every test account must be
   under **Google Auth Platform → Audience → Test users**. Publishing to
   Production is *not* required for `email`/`profile`.

If `tool/google_signin_check.sh` prints `MATCH` for both the signer and the
client ID (as it does for this build), the app side is provably correct and the
remaining cause is one of the five above — there is nothing left to change in
the Dart or Gradle code.

#### If it still fails with a verified APK

Use one of these, in order:

- **Free the pair.** In the project that owns it: Credentials → the Android row
  → delete. A deleted *project* also frees it, but only after its 7-day
  pending-deletion window.
- **Mint a fresh, app-scoped SHA-1** (recommended — does not touch your other
  apps' debug signature):
  ```sh
  bash tool/new_project_debug_keystore.sh          # dry run
  bash tool/new_project_debug_keystore.sh --yes    # writes android/app/debug.keystore
  ```
  `android/app/build.gradle.kts` picks that key up automatically for debug and
  the debug-signed release build. Register the printed SHA-1 as a **new**
  Android client in project `940621050374`, then `flutter clean` and re-run.
- **Regenerate the machine-wide key** (only if you accept that every Android
  project on this machine changes signature):
  ```sh
  bash tool/regen_debug_keystore.sh --yes
  ```

After any console change: uninstall the app, clear **Google Play services**
cache (Settings → Apps → Google Play services → Storage → Clear cache), and
allow up to a few hours before concluding it did not work.

| Symptom | Cause |
|---|---|
| "an unexpected error occurred" right after picking an account | the old, generic catch-all; the reason is now surfaced (row below) |
| app: *"Google Sign-In is misconfigured for this app: the Android package name + SHA-1 …"* / log: `GoogleSignInExceptionCode.clientConfigurationError` | wrong package/bundle id, or SHA-1 not registered — the classic fallout of renaming the app id (`com.example.*` → `com.salon.*`) |
| app/log: `[28444] developer console is not set up correctly` | no Android OAuth client matches this package + SHA-1, **or** the Android client sits in a different Google Cloud project than the web client |
| `[28444]` even though the Android client clearly exists | the Android client is in a *different project* than the web client, the registered SHA-1 is stale (keystore changed), the `(package, SHA-1)` pair is owned by another project, Play services cached the failure, or the console change has not propagated yet (up to a few hours) — see "Why `[28444]` keeps coming back" above |
| *"the fingerprint you specified is already used by an Android OAuth2 client ID in this project or another project"* when adding the Android client | the `(package, SHA-1)` pair is globally unique and already registered in **another** project — see the last note below (`regen_debug_keystore.sh` is the quick fix) |
| unexpected `canceled` right after picking an account | usually the same config error (Credential Manager masks it) |
| works in debug, fails in release | release keystore SHA-1 not registered |
| `Google Sign-In is not configured on this build` | `GOOGLE_SERVER_CLIENT_ID` missing from the dart-define file |
| `Missing security tokens from Google Authentication.` | the web client id was not honoured as `serverClientId` — check `config/supabase.json` |

> **Seeing "\<package\> and SHA-1 already exist" when creating the Android
> client?** The Android client is already registered — don't create a duplicate.
> Find out *where* it lives with one test:
>
> **Is the web client (`940621050374-…`) listed on the same Credentials page as
> the Android client?**
>
> - **Same page →** the registration is correct, and `[28444]` is Google Play
>   services caching the failure per app: force-stop the app, clear **Google Play
>   services** cache (Settings → Apps → Google Play services → Storage → Clear
>   cache), uninstall + reinstall, and wait a few minutes.
> - **Not on the same page →** the Android client is in a *different* Google
>   Cloud project than the web client, which can never work. Delete it there
>   (pending deletion is fine) and create it in the project that lists the web
>   client.
>
> **Re-read the SHA-1 with `./gradlew signingReport` every time.** The debug
> keystore — and therefore its SHA-1 — can be regenerated (e.g. by Android
> Studio or a fresh machine), silently invalidating a value you registered
> earlier. That alone produces this exact error. `tool/google_signin_check.sh`
> always prints the current value to compare against the console.

> **Seeing "the fingerprint you specified is already used by an Android OAuth2
> client ID in this project or another project"?** A `(package name, SHA-1)`
> pair can be registered **only once across all Firebase and Google Cloud
> projects** (Google's own wording: *"every pairing of a package name and SHA-1
> certificate fingerprint used to create an OAuth 2.0 client ID must be unique
> across all Firebase and Google Cloud projects"*). So this message usually
> means the pair your build signs with already lives in some **other** project —
> which is exactly why the Android client you see in the web client's project
> can have a *different* SHA-1 (or package) and still leave the app stuck on
> `[28444]`.
>
> Two ways out:
>
> 1. **Find and delete the conflicting client** in whichever project holds it
>    (Credentials → the Android row → delete; a deleted *project* also frees the
>    pair, but only after its 7-day pending-deletion window). Then create the
>    Android client in the web client's project.
> 2. **Regenerate the debug keystore for a fresh SHA-1** and register *that* in
>    the web client's project — the new fingerprint is unused, so the
>    uniqueness rule can't block it:
>    ```sh
>    bash tool/regen_debug_keystore.sh          # shows the plan, changes nothing
>    bash tool/regen_debug_keystore.sh --yes    # backs up + regenerates
>    ```
>    Then add the printed SHA-1 to a new Android client for
>    `com.salon.salon_app_view` in project `940621050374`, `flutter clean`, and
>    re-run.
