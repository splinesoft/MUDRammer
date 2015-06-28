# SPLCore [![Circle CI](https://circleci.com/gh/splinesoft/SPLCore.svg?style=svg)](https://circleci.com/gh/splinesoft/SPLCore)

Shared dependencies for [Splinesoft](http://splinesoft.net) apps. SPLCore was extracted from my app [MUDRammer, a Modern MUD Client for iPhone and iPad](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8).

### Additions

Various category additions.

### Models

- `SSMagicManagedObject`: A core `NSManagedObject` subclass with several helpers for use with [MagicalRecord](https://github.com/magicalpanda/magicalrecord).

### SPLCore

- `SPLCore.h`: base header file.
- `SPLDebug.h`: macros and debugging helpers.
- `SPLFloat.h`: helpers for floats and doubles on arm64/armv7. See also [CGFloat in a 64-bit world](http://list.her.sh/cgfloat-and-arm64/).
