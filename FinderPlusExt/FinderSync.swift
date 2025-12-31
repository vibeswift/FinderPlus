import Cocoa
import FinderSync
import Foundation
import OSLog

class FinderSync: FIFinderSync {
    private let manager = AppSettings.shared

    override init() {
        super.init()
        let all = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: .skipHiddenVolumes) ?? []
        FIFinderSyncController.default().directoryURLs = Set(all)
    }

    override var toolbarItemName: String {
        return AppSettings.extensionName
    }
    
    override var toolbarItemToolTip: String {
        return AppSettings.extensionName
    }
    
    override var toolbarItemImage: NSImage {
        let image = NSImage(systemSymbolName: "filemenu.and.selection", accessibilityDescription: "搜索")!
        image.size = NSSize(width: 16, height: 16)
        return image
    }


    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu()
        
        // 一次性获取常用上下文（只调一次 API，性能拉满）
        let selectedURLs = FIFinderSyncController.default().selectedItemURLs() ?? []
        let count = selectedURLs.count
        let isSingle = count == 1
        let isMultiple = count > 1
        let isBlank = count == 0
        let singleURL = selectedURLs.first
        // 扩展名（小写）
       // let ext = isSingle ? singleURL!.pathExtension.lowercased() : ""

        //let startTime = CFAbsoluteTimeGetCurrent()
        for (index, item) in manager.menuItems.enumerated() where item.isEnabled {

            // 判断菜单类型
            let passLocation: Bool = {
                switch menuKind {
                case .toolbarItemMenu:            return item.isToolbarEnabled
                case .contextualMenuForItems:     return item.isContextEnabled
                case .contextualMenuForContainer: return item.isContextEnabled
                case .contextualMenuForSidebar:   return item.isContextEnabled
                @unknown default: return false
                }
            }()
            guard passLocation else { continue }
            
            // 判断文件类型
            if menuKind != .toolbarItemMenu && !item.conditions.isEmpty {
                let allConditionsPassed = item.conditions.allSatisfy { condition in
                    switch condition {
                    case .singleOnly:          return isSingle
                    case .multipleOnly:        return isMultiple
                    case .singleOrBlankOnly:   return isSingle || isBlank
                    case .folderOnly:          return isSingle && (try? singleURL!.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                    case .fileOnly:            return isSingle && (try? singleURL!.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false
                        //                        case .imageOnly:           return imageExtensions.contains(ext)
                        //                        case .videoOnly:           return videoExtensions.contains(ext)
                        //                        case .codeOnly:            return codeExtensions.contains(ext)
                        //                        case .archiveOnly:         return archiveExtensions.contains(ext)
                        //                        case .externalVolumeOnly:  return isExternalVolume
                        //                        case .internalVolumeOnly:  return !isExternalVolume
                        //                        case .hasExtension(let e): return ext == e.lowercased()
                        //                        case .pathContains(let s): return singleURL?.path.contains(s) ?? false
                    }
                }
                guard allConditionsPassed else { continue }
            }
            // 通过所有检查 → 添加菜单
            addMenuItem(to: menu, item: item, index: index)
        }
       // let endTime = CFAbsoluteTimeGetCurrent()
        //Logger.app.info("\(endTime - startTime)")
        return menu
    }
    private func addMenuItem(to menu: NSMenu, item: MenuItem, index: Int) {

        let menuItem = NSMenuItem(title:item.action == "open" ? "用\(item.appName ?? "软件")打开":String(localized: item.title ), action: #selector(menuAction(_:)), keyEquivalent: "")
        menuItem.target = self
        if item.action == "open" {
            menuItem.image = Magic.getAppIcon(bundleID: item.appBundleID ?? Bundle.main.bundleIdentifier ?? "")
        } else {
            menuItem.image = NSImage(systemSymbolName: item.icon, accessibilityDescription: nil)
        }
        
        menuItem.tag = index
        menuItem.representedObject = item.action
        menu.addItem(menuItem)
    }
    // MARK: - 动作
    @objc func menuAction(_ sender: NSMenuItem) {
        let index = sender.tag
        
        // 验证索引有效性
        guard index >= 0 && index < manager.menuItems.count else {
            Logger.app.error("menuAction: invalid tag index: \(index)")
            return
        }
        
        switch manager.menuItems[index].action {
        case "search":
            searchWithHapigo()
        case "open":
            openWithProcess(
                bundleID: manager.menuItems[index].appBundleID ?? "",
                single: manager.menuItems[index].appCategory != "editor"
            )
        case "new":
            newFile()
        case "show":
            showMain()
        case "copypath":
            copyPath()
        default:
            break
        }
    }
    private func urlTemplate(prot:String,path:String) -> String{
        var urlString:String
        switch prot{
            case "hapigo":
            urlString = "hapigo://open?extensionID=FILE&query=\(path)"
            default:
            urlString = "\(prot)://file\(path)"
                
        }
        
        return urlString
    }
    
    func openWithURLScheme(prot: String,onlyCurrentFolder:Bool = false){
        var urlsToOpen:Array<URL>
        //获取 Finder 中选中的文件或文件夹
        let targetURL = FIFinderSyncController.default().targetedURL()
        if onlyCurrentFolder{
            urlsToOpen = targetURL.map{[$0]} ?? []
        } else{
            let selectedURLs = FIFinderSyncController.default().selectedItemURLs() ?? []
            // 如果没有选中内容，就打开当前目录
            urlsToOpen = selectedURLs.isEmpty
                ? (targetURL.map { [$0] } ?? [])
                : selectedURLs
        }
        
 
        for url in urlsToOpen {
            if let openURL = URL(string: self.urlTemplate(prot: prot,path: url.path)) {
                let success = NSWorkspace.shared.open(openURL)
                if !success {
                    Logger.app.error("Open files with \(prot):\(url.path) failed.")
                }
            }
        }
    }


    @objc func searchWithHapigo() {
        openWithURLScheme(prot: "hapigo",onlyCurrentFolder: true)
    }
    

    @objc func newFile() {
        let folderURL  = FIFinderSyncController.default().targetedURL()!
        manager.target = folderURL.path()
        DistributedNotificationCenter.default().post(
            name: .creteNewFile,
            object: nil,
            userInfo:nil
        )
    }
    
    @objc func openWithProcess(bundleID:String,single:Bool = false){
         
        var targetURL = single ? FIFinderSyncController.getSelectedFolder() : FIFinderSyncController.getSelectedItems()
        targetURL.insert(bundleID,at: 0)
        manager.openTarget = targetURL
        DistributedNotificationCenter.default().post(
            name: .openWithT,
            object: nil,
            userInfo:nil
        )
    }
    @objc func copyPath() {
        let paths = FIFinderSyncController.getSelectedItems()
        let pathString = paths.joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pathString, forType: .string)
    }
    @objc func showMain(){
 
        guard let bundleID =  Bundle.main.bundleIdentifier else {
            Logger.app.error("读取 CFBundleIdentifier 失败。")
            return
        }

        let appBundleID = bundleID.replacingOccurrences(of: ".FinderPlusExt", with: "")
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID) else {
            Logger.app.error("找不到应用: \(appBundleID)")
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error = error {
                Logger.app.error("打开主应用失败: \(error)")
            }
        }
    }
}
