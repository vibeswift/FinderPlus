import SwiftUI

@main
struct FinderPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var settings = AppSettings.shared
    var body: some Scene {
        WindowGroup {
            SettingView()
                .environment(settings)
                .frame(width: 640, height: 488)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

 
