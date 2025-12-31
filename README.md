# FinderPlus
<div align="center">
  <img src="https://github.com/vibeswift/FinderPlus/blob/main/ScreenCapture/logo.png" alt="FinderPlus Logo"/>
</div>
FinderPlus is a SwiftUI project with Vibe Coding.

## Features

Adds custom menu items to Finder, You can freely control whether they appear in the toolbar or the Finder context menu.

- **Search**: Opens the Hapigo search box.
- **Copy Path**: Copies the path of the current window or the paths of selected files and folders.
- **Open With App**: Opens files or folders using a specified application. Currently supports two categories of applications—editors and terminals. Not all related applications have been tested, You can add any application to test compatibility.

## Download
You can [download](https://github.com/vibeswift/FinderPlus/releases/latest) the pre-compiled application. 

Since I lack the funds to register for an Apple Developer account, you will need to run the .dmg file and place FinderPlus into the Applications folder and execute the following command in Terminal: `codesign --force --deep --sign - /Applications/FinderPlus.app`. This step is required to allow the application to run normally.

## Preview
![FinderPlus](https://github.com/vibeswift/FinderPlus/blob/main/ScreenCapture/home.png)
![FinderPlus Menu](https://github.com/vibeswift/FinderPlus/blob/main/ScreenCapture/menu.png)
![FinderPlus Apps](https://github.com/vibeswift/FinderPlus/blob/main/ScreenCapture/app.png)
