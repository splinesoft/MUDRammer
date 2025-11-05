# MudBasher — A Modern MUD Client

```
> invoke incantation of build status divination

You move a hand through a series of quick gestures,
your digits twinkling with eldritch potential.
Suddenly, some images form in your mind:
```

![It's dangerous!](https://img.shields.io/badge/You_are_likely_to_be_eaten_by_a-grue-red.svg) [![Take this.](https://img.shields.io/badge/get-lamp-yellow.svg)](http://getlamp.com)

<hr/>

MudBasher was a modern MUD client for iPhone and iPad focused on speed, accessibility, and flexibility. MudBasher was designed and developed by [Jonathan Hersh](#contact) since November 2012. MudBasher's first App Store release in February 2013 was followed by [34 App Store updates](https://github.com/splinesoft/MUDRammer/blob/master/AppStore/updates.txt) as of May 2015 and an open-sourcing in June 2015. MudBasher was removed from the App Store in March 2025.

[MUDs (Multi-User Dungeons)](https://en.wikipedia.org/wiki/MUD) are online multiplayer text-based games. Thousands of players today are on hundreds of MUDs in all manner of worlds: fantasy, absurdist, sci-fi, horror, and more. Many MUDs have been continuously online for decades! MudBasher includes a `DefaultWorlds.plist` with a few interesting default worlds you can try, or you can add your own.

[![MudBasher for iPhone](https://github.com/splinesoft/MUDRammer/raw/master/AppStore/Screenshots/51.png)](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8)

## For Your Eyes Only

MudBasher has been my personal passion project for years. It is an experiment to release my work under such a permissive license. If you want to create your own software based on MudBasher, please make it meaningfully different and not just a clone. Please do not submit your own version of MudBasher to the App Store.

## Getting Started

You'll need Xcode 6.3 or newer.

1. [Install Homebrew](http://brew.sh) if needed, and then `brew update && brew install objc-codegenutils`
2. Clone this repo: `git clone https://github.com/splinesoft/MUDRammer.git && cd MUDRammer`
3. `rake setup` will install RubyGems and CocoaPods. You will be prompted (one time only) to enter values for application secrets, like Hockey API keys. These values are stored securely in the OS X keychain. You can enter a blank space or `-` for these. You should run `rake setup` after updating your local copy from upstream.
4. `open src/Mudrammer.xcworkspace` to build and run. Make sure to select the `MudBasher Dev` Xcode scheme.

Additional `rake` tasks include:

| Task | Description |
| ---- | ----- |
| `rake gems` | Installs RubyGems. |
| `rake pods` | Installs CocoaPods. |
| `rake setup` | Runs `rake gems` and `rake pods` and wipes the build output folder. |
| `rake test` | Builds MudBasher and runs all tests (minimalistic RSpec-style output). |
| `rake lint` | Lints MudBasher with various static analyzers. |
| `rake code` | Generates and prints a single code redeemable on the iTunes store for a free copy of MudBasher. |
| `rake ws` | Strips trailing whitespace from all project source files. Requires [these Swift playgrounds](https://github.com/jhersh/playgrounds). |

## Notes

- MudBasher builds with the iOS 8 SDK and has a minimum deployment target of iOS 7. MudBasher will soon build with the iOS 9 SDK and require a minimum deployment target of iOS 8: [#254](https://github.com/splinesoft/MUDRammer/pull/254)
- The project's `CFBundleShortVersionString` is `trolololol` and its `CFBundleVersion` is `1337`. These values are intentionally obvious to indicate Debug builds. The correct marketing version and build numbers are filled in by Jenkins at release build time by [my build script, SSBuild](https://github.com/splinesoft/SSBuild).
- MudBasher has a separate app icon to distinguish Debug builds, [no code required!](http://list.her.sh/beta-app-icons)

## Contributing

Pull requests are welcome! Fork the repo and make your changes on a branch. You can run `rake test` locally to ensure the tests pass before opening a pull request.

## License

MudBasher's source code is available under the MIT license. See the `LICENSE` file for more details.

Although technically permitted by the license terms, please do not submit your own version of MudBasher to the App Store.

Fonts, images, and sounds bundled with MudBasher are licensed free for commercial use.

## About the Name

MudBasher - because sometimes you need to bash your way through those MUDs!

## Contact

Jonathan Hersh

- [Electronic Mail](mailto:jon@her.sh)
- **@jhersh** on [Github](https://github.com/jhersh)
- [her.sh](https://her.sh)
