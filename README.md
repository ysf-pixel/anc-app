# ANC

ANC is a native SwiftUI iPhone app for viewing microphone level, selecting an available input route, and experimenting with phase-analysis parameters. It is **not true active noise cancellation**. iOS cannot use ordinary app APIs to impose low-latency anti-noise on system-wide audio or reliably cancel physical ambient sound. The app deliberately does not play captured microphone audio through the speaker because that can create severe acoustic feedback.

## Requirements

- iOS 17 or later
- A physical iPhone for microphone and route testing (the simulator has no meaningful live audio route)
- Xcode 15.4 or newer to develop locally, or GitHub Actions to compile in the cloud

## Run locally

Open `ANC.xcodeproj` in Xcode, choose a physical device, allow microphone access, and press Run. No Apple Developer membership is needed for a personal-device run from Xcode with a free Apple ID, although the provisioning profile expires and some capabilities are unavailable.

## GitHub Actions / no Mac

The repository includes `.github/workflows/ios-build.yml`. After you create a GitHub repository yourself and push this folder, Actions will compile an unsigned simulator and device build on a hosted macOS runner, and upload build products as an artifact.

That artifact is **not an installable signed IPA**. To make an IPA for a device, add an Apple Developer signing certificate, provisioning profile, and matching bundle identifier as GitHub secrets, then extend the workflow with an authenticated archive/export step. Do not upload certificates or provisioning profiles into the repository.

Suggested commands after creating an empty GitHub repository (replace the URL):

```powershell
cd ANC
git init
git add .
git commit -m "Initial ANC app"
git branch -M main
git remote add origin https://github.com/YOUR-NAME/ANC.git
git push -u origin main
```

Choose public/private visibility yourself before creating the remote repository. A free GitHub account can run public-repository Actions; private-repository availability/minutes depend on the account plan.

## Sideloading

An IPA has to be signed for the target device. The straightforward routes are:

1. Use Xcode and your Apple ID to install a development build on your own device.
2. Use a paid Apple Developer account and configure CI signing secrets to export an IPA.
3. Use a sideloading tool that signs with your Apple ID, subject to its current limitations and certificate renewal requirements.

Never share your Apple ID password, signing certificate, private key, or provisioning profile in an issue, repository, or chat.

## Future rootless companion boundary

`ANC/Companion` only defines protocol and client interfaces; it ships no jailbreak code, does not attempt privilege escalation, and performs no IPC. A future rootless Theos package can implement `ANCCompanionTransport` behind this boundary, with the app retaining a safe in-app fallback.
