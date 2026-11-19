# Building Wraithgram

🇬🇧 English · [🇷🇺 Русский](building.ru.md)

Wraithgram is distributed as source code only: there are no ready-made IPA files. This guide shows how to
build the app yourself, either on your own Mac or on a GitHub-hosted Mac through GitHub Actions.

- [Before you start: your own api_id and bundle ID](#before-you-start-your-own-api_id-and-bundle-id)
- [Build on your Mac](#build-on-your-mac)
- [Build with GitHub Actions](#build-with-github-actions)
- [Push notifications](#push-notifications)
- [Troubleshooting](#troubleshooting)

## Before you start: your own api_id and bundle ID

> [!WARNING]
> The configuration template, `build-system/wraithgram-configuration.example.json`, contains **Telegram's own
> public values** from the [Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS) repository:
> `api_id` `8`, its `api_hash`, and the bundle ID `ph.telegra.Telegraph`. They are for simulator use only.
> The GitHub Actions device workflow now requires your own API credentials and a reverse-DNS bundle ID;
> it stops before building if either credential is missing or malformed.

| Field | What to put there |
|-------|-------------------|
| `api_id`, `api_hash` | Your own values. Sign in at [my.telegram.org](https://my.telegram.org), open **API development tools** and create an application. Telegram's [rules for developers](https://github.com/TelegramMessenger/Telegram-iOS#creating-your-telegram-application) require your own `api_id`. |
| `bundle_id` | Your own reverse-DNS identifier, for example `com.froggram.ios`. An IPA with `ph.telegra.Telegraph` would install over the official Telegram app, so the device builds stop when they see it. |

The build scripts check the configuration with `build-system/WGConfigCheck.py`: they print a warning while
`api_id` is `8`, and a device build stops while `bundle_id` is `ph.telegra.Telegraph`.

## Build on your Mac

### Requirements

- A Mac with the Xcode version named in [`versions.json`](../../versions.json) (`"xcode"`), selected with
  `sudo xcode-select -s /Applications/Xcode.app`. The scripts pin the build to that Xcode, so a newer beta
  installed next to it is ignored.
- Python 3 and Git.
- Plenty of free disk space. On our Mac, the build outputs took about 30 GB and Bazel's cache in
  `~/telegram-bazel-cache` grew to about 50 GB over many builds.

Bazel itself is downloaded into `build-input/` on the first run.

### Steps

1. Clone the repository with its submodules:

   ```sh
   git clone --recursive -j8 https://github.com/Wraithgram/ios.git
   cd ios
   ```

2. Create your configuration file from the template:

   ```sh
   cp build-system/wraithgram-configuration.example.json build-system/wraithgram-configuration.json
   ```

   The file is in `.gitignore`. Put your own `api_id`, `api_hash` and `bundle_id` into it, as described in
   [Before you start](#before-you-start-your-own-api_id-and-bundle-id). For a simulator build you can leave
   the template's values.

3. Build for the simulator:

   ```sh
   build-system/WGBuild.sh
   ```

   The script prints its progress and writes the full log to `/tmp/wg-build.log`. It ends with `BUILD OK` and
   the app is in `bazel-bin/Telegram/Telegram.ipa`. The simulator ignores signatures: without profiles of your
   own, the script signs with Telegram's test profiles from `build-system/fake-codesigning`.

4. Build an IPA for your iPhone:

   ```sh
   build-system/WGBuildResign.sh 1
   ```

   `1` is the build number. The result is `build-output/ipa/Wraithgram-for-resign.ipa` with your `bundle_id`
   and all app extensions (share sheet, widgets, notifications, Siri).

5. Install the IPA with a signing app on the iPhone, such as ESign or LCSign, and your own certificate. The
   signing app replaces the build's signature with yours.

To sign on the Mac with your own Apple Developer profiles instead of a signing app, see
[Signing with your own profiles](codesigning.md).

### Optional: the VPN core

The VPN feature needs the Xray core, which is not built by default:

```sh
Wraithgram/Features/Vless/Core/build-core.sh
```

It needs Go 1.26 or newer and downloads [Xray-core](https://github.com/XTLS/Xray-core) on the first run.
Without the core the app still builds, and the VPN screen says that the core is not included.

## Build with GitHub Actions

The workflow `.github/workflows/build.yml` ("Build IPA for re-signing") runs `WGBuildResign.sh` on a
GitHub-hosted Mac and gives you the IPA as a download. It runs only when you start it. Standard GitHub-hosted
runners are free for public repositories.
In our test run on the `xcode-27` runner, the whole run took about 1 hour 20 minutes and the IPA artifact
was about 78 MB.

1. Fork the repository on GitHub.
2. Optional, but recommended: in your fork, open **Settings → Secrets and variables → Actions** and add two
   repository secrets, `TELEGRAM_API_ID` and `TELEGRAM_API_HASH`, with your values from
   [my.telegram.org](https://my.telegram.org). The device workflow stops before compilation if either secret is missing.
3. Open the **Actions** tab of your fork and enable workflows if GitHub asks.
4. Select **Build IPA for re-signing**, then **Run workflow**, and fill in:
   - **bundle_id**: your own bundle ID, for example `com.froggram.ios`;
   - **build_number**: any number, `1` by default;
   - **runner**: leave `xcode-27`. The runner must have the Xcode version from `versions.json`; GitHub
     publishes the Xcode versions of each runner in
     [actions/runner-images](https://github.com/actions/runner-images).
5. When the run finishes, open it and download the artifact `Wraithgram-for-resign-<build number>` at the
   bottom of the run page. GitHub keeps it for 3 days. The download is a ZIP with
   `Wraithgram-for-resign.ipa` inside.
6. Install the IPA with a signing app, as in [step 5](#steps) of the Mac build.

If the run fails, it uploads the build log as the artifact `build-log`.

## Push notifications

In our tests, a build with a newly created `api_id` received no push notifications: when the app registered for
them, Telegram's server answered `APP_PUSH_CERT_MISSING`, that is, Telegram has no Apple push certificate for
that `api_id`. Messages arrived when the app was opened. Everything else works without push notifications.

## Troubleshooting

| Message | What to do |
|---------|------------|
| `ERROR: build-system/wraithgram-configuration.json is missing` | Do step 2 of [Build on your Mac](#steps). |
| `ERROR: bundle_id in … is Telegram's own (ph.telegra.Telegraph)` | Put your own `bundle_id` into the configuration file (or into the **bundle_id** input of the workflow). |
| `WARNING: … uses Telegram's own api_id (8)` | Put your own `api_id` and `api_hash` into the configuration file (or into the workflow's secrets). |
| `ERROR: … neither applies nor is already applied` | A submodule changed. Run `git submodule update --init --recursive` and build again. |
| `/Applications/Xcode_….app is not on this runner` (GitHub Actions) | Choose a runner label that has that Xcode version. |
