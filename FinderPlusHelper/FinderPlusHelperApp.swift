import SwiftUI
import OSLog

@main
struct FinderPlusHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    

    func applicationDidFinishLaunching(_ notification: Notification) {
 
        let settings = AppSettings.shared
        DistributedNotificationCenter.default().addObserver(forName: .openWithT, object: nil, queue: .main) { n in
            let items = settings.openTarget
            Magic.runAppWithProcess(path:items)
        }
        DistributedNotificationCenter.default().addObserver(
            forName: .creteNewFile,
            object: nil,
            queue: .main
        ) { n in
            if !Magic.refreshFullDiskAccessStatus() {
                return
            }

            if let folderPath = settings.target {
                let decodedPath = folderPath.removingPercentEncoding ?? folderPath
                let fileURL = URL(filePath: decodedPath).appendingPathComponent("helper_created_\(Int(Date().timeIntervalSince1970)).txt")
                do {
                    try Data().write(to: fileURL)
                } catch let error as NSError {
                    Logger.app.error("创建失败: \(error)")
                    switch error.code {
                    case 513://权限不足
                        if folderPath.starts(with: "/Volumes/"){
                            Logger.app.error("外置硬盘权限不足")
                        }
                    default:
                        Logger.app.error("\(error)")
                    }
                }
            }
        }
    }
}
