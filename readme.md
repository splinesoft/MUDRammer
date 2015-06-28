# MUDRammer — A Modern MUD Client

[![Download MUDRammer on the App Store](http://linkmaker.itunes.apple.com/images/badges/en-us/badge_appstore-lrg.svg)](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8)

```
> invoke incantation of build status divination

You move a hand through a series of quick gestures, 
your digits twinkling with eldritch potential. 
Suddenly, some images form in your mind:
```

[![Circle CI](https://circleci.com/gh/splinesoft/MUDRammer.svg?style=svg)](https://circleci.com/gh/splinesoft/MUDRammer) [![Coverage Status](https://coveralls.io/repos/splinesoft/MUDRammer/badge.svg)](https://coveralls.io/r/splinesoft/MUDRammer)

<hr/>

MUDRammer is a modern MUD client for iPhone and iPad focused on speed, accessibility, and flexibility. MUDRammer has been designed and developed by [Jonathan Hersh](#contact) since November 2012. MUDRammer's first App Store release in February 2013 was followed by [34 App Store updates](https://github.com/splinesoft/MUDRammer/blob/master/AppStore/updates.txt) as of May 2015. MUDRammer was open-sourced in June 2015.

[MUDs (Multi-User Dungeons)](https://en.wikipedia.org/wiki/MUD) are online multiplayer text-based games. Thousands of players today are on hundreds of MUDs in all manner of worlds: fantasy, absurdist, sci-fi, horror, and more. Many MUDs have been continuously online for decades! MUDRammer includes a `DefaultWorlds.plist` with a few interesting default worlds you can try, or you can add your own.

MUDRammer is available for sale on the [App Store](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8). Although this repository will allow you to build and run MUDRammer from source, please purchase MUDRammer on the [App Store](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8) to support continued development.

[![MUDRammer for iPhone](https://github.com/splinesoft/MUDRammer/raw/master/AppStore/Screenshots/51.png)](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8)

## Getting Started

You'll need Xcode 6.3 or newer.

1. [Install Homebrew](http://brew.sh) if needed, and then `brew update && brew install objc-codegenutils`
2. Clone this repo: `git clone git@github.com:jhersh/MUDRammer.git && cd MUDRammer`
3. `rake setup` will install RubyGems and CocoaPods. You will be prompted (one time only) to enter values for application secrets, like Hockey API keys. These values are stored securely in the OS X keychain. You can enter a blank space or `-` for these. You should periodically run `rake setup` to ensure you're up to date with all dependencies.
4. `rake test` will build MUDRammer and run all tests (minimalistic RSpec-style output).
5. `rake lint` will lint MUDRammer with various static analyzers. [FauxPas.app](http://fauxpasapp.com) is required for one of the linting steps.
6. `open src/Mudrammer.xcworkspace` to build and run. Make sure to select the `MUDRammer Dev` Xcode scheme.

## Notes

- The Xcode project has a `CFBundleIdentifier` of `com.splinesoft.theMUDRammer`. I have never owned the domain `splinesoft.com`, only `splinesoft.net`, so the correct bundle ID should be `net.splinesoft.theMUDRammer`. I made this naming mistake in 2012. Bundle IDs cannot be changed after app release, so Xcode has shamed me for my mistake every time I open the project, thousands of times over the last few years.
- The project's `CFBundleShortVersionString` is `trolololol` and its `CFBundleVersion` is `1337`. These values are intentionally obvious to indicate Debug builds. The correct marketing version and build numbers are filled in by Jenkins at release build time by [my build script, SSBuild](https://github.com/splinesoft/SSBuild).
- MUDRammer has a separate app icon to distinguish Debug builds, [no code required!](http://list.her.sh/beta-app-icons)

## For Your Eyes Only

MUDRammer has been my personal passion project for years. It is an experiment to release my work under such a permissive license. If you use MUDRammer, please purchase a copy from the [App Store](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8) rather than simply running it locally from source. If you want to create your own software based on MUDRammer, please make it meaningfully different and not just a clone.

## Contributing

Pull requests are welcome! Fork the repo and make your changes on a branch. You can run `rake test` locally to ensure the tests pass before opening a pull request.

## License

MUDRammer's source code is available under the MIT license. See the `LICENSE` file for more details.

Although technically permitted by the license terms, please do not submit your own version of MUDRammer to the App Store.

Fonts, images, and sounds bundled with MUDRammer are licensed free for commercial use.

## About the Name

I've been very fortunate to meet people from all over the world in my years of mudding. One of my more colorful Dutch mudding acquaintances has played for years with a character named "Mudrammer". It is a ridiculous and silly name, but it still makes me :laughing:

## Contact

Jonathan Hersh

- [Electronic Mail](mailto:jon@her.sh)
- [Github](https://github.com/jhersh)
- [her.sh](http://her.sh)
