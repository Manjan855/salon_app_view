# Email + password sign-in and password reset

## Why "Invalid login credentials" happens

`AuthProvider.login()` calls Supabase `signInWithPassword`. Supabase returns
**`Invalid login credentials`** when the email/password pair does not match any
user. The app only displays that message — it is not an app bug.

The usual causes, in order:

1. **No account exists** for that email (most common — sign up first).
2. **Wrong password** (typo, or it was changed).
3. **The account was created with "Continue with Google".** OAuth users have
   **no password**, so password login can never succeed for them. They must
   either keep using Google, or set a password via the reset flow below.

Project settings that matter (checked via `GET /auth/v1/settings`):

| Setting | Current value | Meaning |
|---|---|---|
| `external.email` | `true` | email/password provider is on |
| `disable_signup` | `false` | new accounts can be created |
| `mailer_autoconfirm` | `true` | no confirmation email needed |

## The reset flow

```
Login screen
  └─ "Forgot Password?"  →  dialog asks for email
        └─ AuthProvider.sendPasswordResetEmail(email)
              └─ supabase.auth.resetPasswordForEmail(redirectTo: salonappview://auth-callback)
                    └─ user opens the email link on the same device
                          └─ supabase_flutter deep-link observer exchanges the PKCE code
                                └─ AuthChangeEvent.passwordRecovery
                                      └─ _PasswordRecoveryHandler pushes ResetPasswordScreen
                                            └─ AuthProvider.updatePassword(newPassword)
                                                  └─ supabase.auth.updateUser(UserAttributes(password: …))
                                                        └─ home
```

### Why the PKCE detail matters

`supabase_flutter` runs in `AuthFlowType.pkce` (see `lib/main.dart`).
`exchangeCodeForSession` stores the event name next to the code verifier and
re-emits `AuthChangeEvent.passwordRecovery`, so the app can tell a reset link
apart from a normal sign-in. The link must therefore be opened **on the same
device/build that requested it** — the code verifier is local.

### Redirect URL allow list

Supabase rejects any `redirect_to` that is not allow-listed. This project has
already saved `salonappview://auth-callback` under
**Authentication → URL Configuration → Redirect URLs** (see
`supabase/README.md`). If you ever change `AppEnv.authRedirectUrl`, update:

- `android/app/src/main/AndroidManifest.xml` (VIEW/BROWSABLE intent-filter)
- `ios/Runner/Info.plist` (`CFBundleURLTypes`)
- the Supabase Redirect URLs list

`test/deep_link_test.dart` fails if the first two drift apart.

## Testing it

```sh
flutter run --dart-define-from-file=config/supabase.json
```

1. Sign up a throwaway account with a known password.
2. Log out, then log in with that email + password — it should reach the home
   screen (or the phone-details screen if the profile is incomplete).
3. Tap **Forgot Password?**, enter the same email, and send the link.
4. Open the email **on the phone** (the emulator/browser can open the custom
   scheme). The app should land on **Set a new password**.
5. Choose a new password → you are signed in.

To check the backend directly (no app involved):

```sh
curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_PUBLISHABLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"your-password"}'
```

A `200` with `access_token` means the credentials are valid; `400` with
`Invalid login credentials` means they are not.

## Notes

- Passwords are never trimmed. `register_screen.dart` previously trimmed the
  password on sign-up but not on login, so a password with a leading/trailing
  space could be created but never used. Fixed.
- `register_screen.dart` now stops and shows the error if the automatic login
  after sign-up fails, instead of navigating to the profile screen with no
  session.
- If Supabase's built-in email is rate-limited, resets may fail with
  "email rate limit exceeded". Configure custom SMTP under
  **Project Settings → Auth → SMTP** for production.
