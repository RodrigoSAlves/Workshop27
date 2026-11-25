# Workshop27: Music Library

A small programmatic UIKit Music Library app, modernized for iOS 27 from the "before" app of the workshop.

- Scene life cycle (`SceneDelegate`, scene manifest in `Info.plist`). The app delegate only does app-wide setup
- No idiom, `UIScreen.main` or orientation checks: layout comes from the container (`effectiveContentSize`, `bounds`) and size classes
- Explore is a single compositional-layout collection view. Liked Songs and playlists use self-sizing table headers and rows
- The mini player is the tab bar controller's `bottomAccessory`
- Trait changes use `registerForTraitChanges` and automatic tracking in `updateProperties()`
- No `canOpenURL` probing: Settings opens Music with `UIScene.open` and handles failure
- `UIRequiresFullScreen` is still set on purpose. Remove it (TN3192) once resizing has been tested on iPad

Deep links: `musiclib://explore`, `musiclib://liked`, `musiclib://settings`. Home-screen quick action: *Liked Songs*.

## Building

Builds with Xcode 27.1 (iOS 27 SDK) with one warning, the deliberate `UIRequiresFullScreen` deprecation. The deployment target is iOS 26.5, because the mini player uses `UITabAccessory`.
