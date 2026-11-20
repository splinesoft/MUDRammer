#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo "Building the iPhone app requires macOS and Xcode." >&2
  exit 1
fi
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Select a full Xcode installation in Xcode > Settings > Locations > Command Line Tools." >&2
  exit 1
fi

python3 scripts/prepare-ios.py
action="${1:-build}"
case "$action" in
  build)
    destination="${IOS_DESTINATION:-generic/platform=iOS Simulator}"
    ;;
  test)
    if [[ -n "${IOS_DESTINATION:-}" ]]; then
      destination="$IOS_DESTINATION"
    else
      simulator_id=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
phones = [d for runtime, group in devices.items() if ".iOS-" in runtime
          for d in group if d.get("isAvailable") and d["name"].startswith("iPhone")]
if not phones:
    sys.exit("Install an iOS Simulator runtime in Xcode > Settings > Components.")
print(phones[0]["udid"])
')
      destination="platform=iOS Simulator,id=$simulator_id"
    fi
    ;;
  *)
    echo "Usage: bash scripts/build-ios.sh [build|test]" >&2
    exit 2
    ;;
esac

mkdir -p output
xcodebuild -workspace src/Mudrammer.xcworkspace \
  -scheme 'MUDRammer Dev' -configuration Debug \
  -destination "$destination" -derivedDataPath output/DerivedData \
  CODE_SIGNING_ALLOWED=NO "$action" 2>&1 | tee "output/ios-${action}.log"
