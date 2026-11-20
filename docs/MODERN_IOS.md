# Modern iPhone update

This checkout contains a compatibility update targeting iOS 15 and later. The
Objective-C app, saved-world data model, terminal, aliases, triggers, and gags
are retained. It needs a build and device test on a Mac before it can be called
working on current iPhones. Source and project checks on Windows are not a
substitute for that validation.

## Build on your Mac

1. Install a current full version of Xcode and an iOS Simulator runtime. Open
   Xcode once to finish installing its components. Select it under **Xcode >
   Settings > Locations > Command Line Tools**.
2. Copy this entire updated folder to your Mac, or extract the supplied ZIP.
   Cloning the upstream GitHub repository alone will not include these local
   changes.
3. In Terminal, open this folder and run:

   ```sh
   bash scripts/build-ios.sh
   ```

   This prepares the bundled headers and builds for the iOS Simulator. No
   Homebrew tools, CocoaPods installation, API secrets, or Apple signing account
   are needed for this step. The build log is `output/ios-build.log`.
4. Run the existing unit tests:

   ```sh
   bash scripts/build-ios.sh test
   ```

   The script selects an installed iPhone simulator. To choose one explicitly:

   ```sh
   IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' bash scripts/build-ios.sh test
   ```

   Substitute a name listed by `xcrun simctl list devices available`.
5. Open `src/Mudrammer.xcworkspace`, select **MUDRammer Dev**, select an iPhone
   simulator, and press Run.

If a build fails, the first compiler error and `output/ios-build.log` identify
the next compatibility issue to resolve. This update has not been compiled
with Xcode in the Windows development environment.

## Install on your iPhone

After the simulator build succeeds, connect your iPhone to the Mac. In Xcode,
select the **MUDRammer** app target and **Signing & Capabilities**:

- Leave automatic signing enabled and choose your own Apple development team.
- Change `org.mudrammer.community` to a unique bundle identifier you control.
- Select your connected iPhone as the run destination, enable Developer Mode
  on the phone if prompted, and press Run.

The command-line build script disables signing for simulator verification;
use Xcode to sign and install on a physical device. A different bundle identifier
installs a separate app and does not inherit the App Store app's saved data.
Copying the project does not copy saved worlds or settings off an existing phone.

## Changes in this checkout

- iOS 15 minimum for the app, tests, and bundled dependency targets; current
  SDK selection; automatic signing; valid version/build values; modern zlib stub.
- A launch storyboard replaces fixed-size launch images and the old splash SDK.
- Terminal content stays within the safe area in portrait and landscape. The
  input bar follows UIKit's keyboard layout guide, supports interactive dismissal,
  and retains the Bluetooth keyboard setting.
- The in-app browser uses WKWebView with swipe navigation, reload, sharing, and
  native browsing Handoff. Web content may load HTTP links from MUD servers;
  other networking retains the system's transport settings.
- Timeout reminders use UserNotifications. Returning to the app clears the pending
  and delivered timeout reminder. This does not extend iOS background execution
  time or guarantee that a MUD connection remains alive in the background.
- HockeyApp analytics/crash reporting, UserVoice, generated secrets, the old web
  and Handoff libraries, and the old keyboard library are excluded from the build.
  Contact opens this fork's GitHub issues page. Unused UIWebView implementations
  in BlocksKit and QuickDialog are excluded as well.
- Image accessor source files are checked in under `src/Mudrammer/Generated`.
  There is no dependency on `/usr/local/bin/objc-assetgen`.
- Original developer signing identifiers are removed from the build. iCloud theme
  sync is off by default so local builds work without iCloud provisioning. Local
  preferences continue to work. To restore sync, configure your own iCloud KVS
  capability and entitlements, then define `MUDRAMMER_ENABLE_ICLOUD=1` for the app.

## Dependency maintenance

The checked-in `src/Pods` sources and Xcode project are the build inputs. Do not
run the historical `rake setup` or `pod install`: they use an old dependency
manifest and can overwrite these project changes. `Podfile`, lockfiles, and the
old Ruby setup are retained as historical dependency records. The legacy support
SDK source folders remain in the repository for provenance, but their targets
are removed from the build graph.

The remaining bundled libraries are still old versions. Updating them and
auditing a release's privacy declarations are separate work before distribution.
This is a device compatibility update, not an App Store submission package.

## Device verification

After compiling, check these behaviors on your iPhone:

1. Fresh launch and welcome, then add a world and connect to a known MUD.
2. Send commands and inspect ANSI colors, scrolling, aliases, triggers, gags,
   command history, and multiple sessions.
3. Show/hide the keyboard, rotate both ways, toggle the top bar, and confirm no
   control sits under the notch or home indicator. Test a hardware keyboard if used.
4. Open a web link, navigate and return, share a page, and test `telnet://` links.
5. Deny and allow notification permission, background and return, then relaunch
   and confirm saved worlds and preferences persist. Check VoiceOver and speech.
6. If an iPad is used, also check rotation and a floating keyboard.
