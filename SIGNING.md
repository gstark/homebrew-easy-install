# Signing and Notarization Setup

CI signs and notarizes the app when the repository secrets below exist.
Without the secrets, CI falls back to an ad-hoc signature.

## Required secrets

| Secret | Content |
| --- | --- |
| `MACOS_CERT_P12` | Base64 of the exported Developer ID Application certificate (.p12) |
| `MACOS_CERT_PASSWORD` | Password of the .p12 file |
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect API issuer ID |
| `ASC_API_KEY_P8` | Full text content of the API key .p8 file |

## Step 1: Create the Developer ID Application certificate

Only the Account Holder of the Apple Developer team can create this
certificate type.

1. Open Xcode.
2. Open Settings, then Accounts.
3. Select your team.
4. Click Manage Certificates.
5. Click the plus button.
6. Select "Developer ID Application".

## Step 2: Export the certificate

1. In Manage Certificates, right-click the new Developer ID Application
   certificate.
2. Select "Export Certificate".
3. Save it as `DeveloperID.p12` and set a password.

## Step 3: Create the App Store Connect API key

Notarization uses this key.

1. Open https://appstoreconnect.apple.com/access/integrations/api
2. Generate a Team Key with the Developer role.
3. Record the Key ID and the Issuer ID.
4. Download the `.p8` file. Apple permits one download only.

## Step 4: Add the secrets

Run these commands from the repository directory:

```
base64 -i DeveloperID.p12 | gh secret set MACOS_CERT_P12
gh secret set MACOS_CERT_PASSWORD
gh secret set ASC_KEY_ID
gh secret set ASC_ISSUER_ID
gh secret set ASC_API_KEY_P8 < AuthKey_XXXXXXXXXX.p8
```

Each command without a redirect prompts for the value.

## Step 5: Verify

1. Push a commit or a `v*` tag.
2. Confirm that the "Notarize and staple" step passes.
3. Download the zip, unzip it, and run:
   `spctl -a -vv "Homebrew Installer.app"`
4. The output must contain `source=Notarized Developer ID`.

## Local signed build

```
CODESIGN_IDENTITY="Developer ID Application" ./build.sh
```
