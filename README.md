# Workshop27: Music Library (legacy PoC)

A small UIKit Music Library app, **written on purpose with the layout practices that iOS 27 deprecates or discourages**. It's the "before" app for the iOS 27 workshop: we run Apple's skills / agents against it and compare the result.

- Swift, programmatic UIKit, no SwiftUI, no storyboards (only the launch screen)
- AppDelegate-only life cycle (no `UISceneDelegate`)
- 3 tabs: **Explore** (featured mix, favourite playlists, new songs, mixes, recently played), **Liked Songs** (persisted likes, play/shuffle, swipe to unlike), **Settings** (streaming quality, playback toggles, theme, connected apps, layout diagnostics)
- Nothing actually plays. A fake "now playing" mini player floats above the tab bar
- All data is synthetic (`Model/MusicLibrary.swift`)

Every bad practice is marked in the code with `⚠️ BAD PRACTICE`:

```bash
grep -rn "⚠️" Workshop27
```

## Building

| Toolchain | Result |
|---|---|
| **Xcode 26.6** (iOS 26.x SDK) | Builds and runs, with ~13 deprecation warnings. This is the baseline. |
| **Xcode 27.x** (iOS 27 SDK) | Builds, then **fails to launch** on iOS 27: the process starts and exits without a window, and no error is shown. This is the deck's *Scene Lifecycle Requirements* slide, reproduced. |

```bash
DEVELOPER_DIR="/Applications/Xcode 26.6.app/Contents/Developer" xcodebuild -project Workshop27.xcodeproj -scheme Workshop27 -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Deep links: `musiclib://explore`, `musiclib://liked`, `musiclib://settings`. Home-screen quick action: *Liked Songs*.

## Catalogue of bad practices

### 1. Configuration (`Info.plist`)

| Practice | Why it breaks on iOS 27 | Replacement |
|---|---|---|
| No `UIApplicationSceneManifest` | Apps built with the iOS 27 SDK must use the scene life cycle or they fail to launch | Add the scene manifest plus a `UIWindowSceneDelegate` |
| `UIRequiresFullScreen = YES` | Ignored with the iOS 27 SDK, so the app becomes resizable on iPad with no warning | Remove the key and support resizing. To keep the opt-out on older iPadOS, use `UIRequiresFullScreenIgnoredStartingWithVersion` |
| `UIDesignRequiresCompatibility = YES` | Xcode 27 builds ignore it, so Liquid Glass is enforced | Remove the key and adopt Liquid Glass |
| 30 `LSApplicationQueriesSchemes` | The iOS 27 SDK caps the list at 25 | Call `open(_:options:completionHandler:)` and handle failure. Drop the `canOpenURL` probes |

### 2. Life cycle (`AppDelegate.swift`)

| Practice | Replacement |
|---|---|
| `var window` on the app delegate, `UIWindow(frame: UIScreen.main.bounds)` | `UIWindow(windowScene:)` in `scene(_:willConnectTo:options:)` |
| Deep links in `application(_:open:options:)` | `scene(_:willConnectTo:options:)` (cold launch) and `scene(_:openURLContexts:)` |
| Quick actions from `launchOptions[.shortcutItem]` and `application(_:performActionFor:)` | `connectionOptions.shortcutItem` and `windowScene(_:performActionFor:completionHandler:)` |
| `application(_:supportedInterfaceOrientationsFor:)` portrait lock on iPhone | `UIWindowSceneDelegate.supportedInterfaceOrientations(for:)`. Treat it as a preference only, since resizable environments ignore it |
| `applicationWillResignActive` / `DidBecomeActive` | `sceneWillResignActive` / `sceneDidBecomeActive` |
| `(UIApplication.shared.delegate as? AppDelegate)?.window` style access | Pass the scene or window down. Use `view.window?.windowScene` |

### 3. Space proxies (`Support/Device.swift`, used everywhere)

| Helper | Why it's wrong | Replacement |
|---|---|---|
| `Device.isPad` / `isPhone` (idiom) | An iPhone app can be any size (Mirroring, iPad, Duo). The idiom no longer tells you the size | `traitCollection.horizontalSizeClass`, or the container's `bounds.width` against a breakpoint |
| `Device.screenWidth/Height` (`UIScreen.main.bounds`) | Deprecated in iOS 26. The scene may be on another screen or smaller than it | The view's own (or superview's) `bounds`, and `windowScene.effectiveGeometry` |
| `Device.scale`, `Device.hairline` (`UIScreen.main.scale`) | Same as above | `traitCollection.displayScale` |
| `Device.isSmallPhone` (`nativeBounds`) | Detects the device model, not the space | Size classes, Dynamic Type, `UIFontMetrics` |
| `Device.isLandscape` (`statusBarOrientation`) | iPhone Mirroring always reports portrait, even when wide | Size classes or `bounds` |
| `Device.keyWindow` (`UIApplication.shared.windows`) | Deprecated since iOS 15. Ambiguous with multiple scenes | `view.window`, `windowScene.keyWindow` |
| `Metrics.*` | Every constant above is derived from the idiom or screen | Derive from the container and size class at layout time |

### 4. Screens

| Where | Practice | What you'll see when resized |
|---|---|---|
| `MainTabBarController.miniPlayerFrame()` | Manual frame from screen size, key-window safe area and a hard-coded `tabBarHeight = 49/50` | On iPad (iOS 18+) the tab bar is at the top, yet the player still sits above a bottom tab bar that isn't there. In a resized window it lands off-screen or covers content |
| `MainTabBarController.viewWillTransition` | Checks `UIDevice.current.orientation`, ignores `size` | Window resizes that aren't rotations never reposition the player |
| `ExploreViewController.setUpScrollView` | Content width = `UIScreen.main.bounds.width` | Horizontal overflow or clipping when the window is narrower than the screen |
| `ExploreViewController.applyLayoutForCurrentDevice` | Grid columns and card widths from idiom, orientation and screen. Runs only on rotation | A wide iPhone window keeps 2 tiny-text columns. A narrow iPad window keeps 3–4 squashed columns |
| `FeaturedBannerView` / `Metrics.heroHeight` | Height = % of screen height, font size by idiom and model | Huge banner in a short window, tiny one in a tall window |
| `SongCell` | Album/duration columns only when `isPad` | Wide iPhone windows never get them. Narrow iPad windows get them squeezed |
| `SongListViewController.installHeader` | Frame-based `tableHeaderView` sized from screen. Hidden in "landscape" | Header wider than the table. Mirroring never hides it (always "portrait") |
| `SongListHeaderView` | Side-by-side vs stacked chosen by idiom | Wrong arrangement whenever the idiom and the size disagree |
| `SettingsViewController` | Table clamped to 640 pt when `isPad`, full width otherwise | Should use `cellLayoutMarginsFollowReadableWidth` / `readableContentGuide` |
| `SettingsViewController.installedShareTargets`, `openMusicApp` | `canOpenURL` on 30 schemes, `canOpenURL` before `open` | Over the 25 limit. Apple recommends `open` plus failure handling |
| `SongActions.present` | iPad-only popover anchored to the screen centre | Wrong anchor in a non-full-screen window |
| `ArtworkView`, `SettingsViewController` | `traitCollectionDidChange(_:)` | Deprecated since iOS 17. Use `registerForTraitChanges` (17+) or automatic trait tracking in `layoutSubviews` / `viewWillLayoutSubviews` (18+) |
| `ThemeManager.apply` | Theme applied to `UIApplication.shared.windows` | Should go through the scene's windows (or `windowScene.traitOverrides`) |

### Layout Diagnostics

**Settings → Layout Diagnostics** shows what the legacy helpers believe (idiom, `UIScreen.main`, orientation) next to the real `view.bounds`. Resize the window (iPad windowing, iPhone Mirroring on macOS 27, Device Hub resize mode) and watch the two disagree.

## Suggested conversion order

1. Scene life cycle: `SceneDelegate`, scene manifest, move URL, shortcut and orientation handling. Remove `UIRequiresFullScreen` and `UIDesignRequiresCompatibility`.
2. Delete `Device` / `Metrics`, then fix every compile error by asking the container (size class or `bounds`).
3. Replace frame math (mini player, table header) with Auto Layout against `view.safeAreaLayoutGuide` / `tabBar`.
4. Move the Explore screen to `UICollectionViewCompositionalLayout`, with columns from `layoutEnvironment.container.effectiveContentSize`.
5. Trait tracking: `registerForTraitChanges`, or automatic tracking.
6. Cut `LSApplicationQueriesSchemes` and replace `canOpenURL` with `open` plus failure handling.
