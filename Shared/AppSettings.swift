import Foundation
import ObservableDefaults

extension Notification.Name {
    static let creteNewFile = Notification.Name("FinderPlusCreateNewFile")
    static let openWithT = Notification.Name("FinderPlusOpenWithT")
}

enum AppCategory: String, CaseIterable, Identifiable {
    case editor
    case terminal
    
    var id: String { self.rawValue }
    
    // 可选：提供本地化/显示名称
    var displayName: String {
        switch self {
        case .editor: return "Editor"
        case .terminal: return "Terminal"
        }
    }
}


@ObservableDefaults(
    suiteName: "group.com.0x401.FinderPlus",
    prefix: "finderplus_",
    limitToInstance: false
)
class AppSettings {
    static let shared = AppSettings()

    // MARK: - 用户偏好设置
    
    var menuItems:[MenuItem] = MenuItem.defaults
    var target:String? = nil
    var openTarget:[String] = []
    var supportedAppList =  [
        AppCategory.editor.rawValue:["dev.zed.Zed","com.microsoft.VSCode"],
        AppCategory.terminal.rawValue:["com.apple.Terminal","com.googlecode.iterm2"]
    ]
    // MARK: - 私有配置
    static let extensionName = "FinderPlus"

    
    func resetMenuItems() {
        menuItems = MenuItem.defaults
    }
}
