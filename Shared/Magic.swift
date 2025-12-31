//
//  Magic.swift
//  FinderPlus
//
//  Created by 0x400 on 2025/11/12.
//
import Foundation
import FinderSync
import ServiceManagement
import OSLog
import CoreServices
import AppKit
extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "App")
}

enum FinderSyncStatus {
    case registedSameName
    case unregisted
    case enable
    case disable
}

struct Magic{
    // MARK: - 系统偏好设置
    static func openSystemPreferences(settingName: String) {
        switch settingName {
        case "extension":
            FIFinderSyncController.showExtensionManagementInterface()
        case "files":
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
        case "login":
            SMAppService.openSystemSettingsLoginItems()
        default: break
        }
    }
    // MARK: - 检测是否有全盘权限
    static func refreshFullDiskAccessStatus()->Bool {
        do{
            _ = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory().appending("/Library/Containers/com.apple.news"))
            return true
        } catch {
            return false
        }
    }
    // MARK: - Helper 管理
    static func registHelper(_ bundleID:String){
        do {
            try SMAppService.loginItem(identifier: bundleID).register()
            
        } catch {
            Logger.app.error("Helper 注册失败，请在登录项允许: \(error)")
        }
        
    }
    
    static func registHelper(_ bundleID: String, completion: @escaping (Result<SMAppService.Status, Error>) -> Void) {
        //Task {  // 包装成异步 Task，便于 SwiftUI 调用
            do {
                try SMAppService.loginItem(identifier: bundleID).register()
                // 立即查询 status 并返回
                let status = self.refreshRegistStatus(bundleID)
                completion(.success(status))  // 成功返回 status
            } catch {
                Logger.app.error("Helper 注册失败: \(error.localizedDescription)")
                
                // 即使失败，也查询 status（可能为 .notFound 或其他）
                //let status = self.refreshRegistStatus(bundleID)
                completion(.failure(error))  // 失败返回 error，但调用者可忽略并用 status 处理
            }
            
       // }
    }
    
    static func unregisterHelper(_ bundleID:String) {
        do {
            try SMAppService.loginItem(identifier: bundleID).unregister()
        } catch {
            Logger.app.error("取消注册 Helper 失败: \(error)")
        }
    }
    static func refreshRegistStatus(_ bundleID:String)-> SMAppService.Status {
          return SMAppService.loginItem(identifier: bundleID ).status
    }
    
    // MARK: 扩展
    static func isExtensionEnabled() -> Bool {
        return FIFinderSyncController.isExtensionEnabled
    }
    
    static func getFinderSyncStatus(extID:String,extPath:String)-> FinderSyncStatus {
        //pluginkit -mvi "com.0x401.FinderPlus.FinderPlusExt"
        //- com.0x401.FinderPlus.FinderPlusExt(0.9)    C3307A44-556B-4718-A9DB-9F84AD71C73A    2025-12-31 01:19:50 +0000    /Applications/FinderPlus.app/Contents/PlugIns/FinderPlusExt.appex
        var status:FinderSyncStatus = .unregisted
        let task = Process()
        task.launchPath = "/usr/bin/pluginkit"
        task.arguments = ["-mvi", extID]

        let pipe = Pipe()
        task.standardOutput = pipe

        try? task.run()
        task.waitUntilExit()
        
        let appPath = Bundle.main.bundleURL.path
        let extPath = "\(appPath)/Contents/PlugIns/FinderPlusExt.appex"

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            if output.contains(extPath){
                if output.starts(with: "+") {
                    status = .enable
                } else if output.starts(with: "-") {
                    status = .disable
                }
                
            } else {
                status = .registedSameName
            }
        } else {
            status = .unregisted
        }
        return status
    }
    
    static func registerFinderSync(at extPath:String)->Bool {
        // pluginkit -a /Applications/FinderPlus.app/Contents/PlugIns/FinderPlusExt.appex

        let task = Process()
        task.launchPath = "/usr/bin/pluginkit"
        task.arguments = ["-a", extPath]
        try?  task.run()
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            Logger.app.error("FinderSync 注册失败")
            return false
        } else {
            Logger.app.info("注册")
            return true
        }
    }
    
    
    static func enableFinderSyncExtension(_ extID:String) ->Bool {
        var enable = false
        let appPath = Bundle.main.bundleURL.path
        let extPath = "\(appPath)/Contents/PlugIns/FinderPlusExt.appex"
        switch getFinderSyncStatus(extID: extID, extPath: extPath){
        case .disable:
            Logger.app.info("未启用")
            let enableTask = Process()
            enableTask.launchPath = "/usr/bin/pluginkit"
            enableTask.arguments = ["-e", "use", "-i", extID]
     
            try?  enableTask.run()
            enableTask.waitUntilExit()
            if enableTask.terminationStatus != 0 {
                Logger.app.error("启用失败")
                enable  = false
            } else {
                Logger.app.info("成功启用")
                enable  = true
            }
        case .enable:
            Logger.app.info("已启用")
            enable  = true
        case .registedSameName:
            Logger.app.info("包含同名")
            enable  = false
        case .unregisted:
            Logger.app.info("未注册")
            enable  = false
        }
        return enable
    }
    
    
    static func disableFinderSyncExtension(_ extID:String) ->Bool {
        let enableTask = Process()
        enableTask.launchPath = "/usr/bin/pluginkit"
        enableTask.arguments = ["-e", "ignore", "-i", extID]
 
        try?  enableTask.run()
        enableTask.waitUntilExit()
        if enableTask.terminationStatus != 0 {
            Logger.app.error("FinderSync 禁用失败")
            return false
        } else {
            Logger.app.error("FinderSync 禁用成功")
            return true
        }
    }

    struct ProcessItem {
        let name:String
        let launchPath:String
        var arguments:[String]
        static let open = ProcessItem(name: "open", launchPath: "/usr/bin/open", arguments: ["-b"])
    }
    
    static func runAppWithProcess(path:[String]){
        let task = Process()
        var process = ProcessItem.open
        process.arguments.append(contentsOf: path)
        task.launchPath = process.launchPath
        task.arguments = process.arguments
        do{
            try  task.run()
            task.waitUntilExit()
            if task.terminationStatus != 0 {
                Logger.app.error("\(process.name)执行失败")
            }
        } catch {
            Logger.app.error("\(error)")
        }
    }

    
    static func loadAllApps() async -> [MacApp] {
        var foundApps: [MacApp] = []
        var seenPaths = Set<URL>()          // 即时去重神器！
        // var seenInodes = Set<NSObject>() // 更极致可加这个（后面解释）
        
        let fileManager = FileManager.default
        let applicationsURLs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: NSHomeDirectory() + "/Applications")
        ]
        
        for baseURL in applicationsURLs {
            guard let enumerator = fileManager.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            while let fileURL = enumerator.nextObject() as? URL {
                guard fileURL.pathExtension.lowercased() == "app" else { continue }
                
                // 关键：解析符号链接，拿到真实路径
                let realURL = fileURL.resolvingSymlinksInPath()
                
                // 即时去重！见过就直接跳过
                if seenPaths.contains(realURL) {
                    continue  // 已经加过了，跳过！
                }
 
                
                if let app = makeApp(from: realURL) {
                    foundApps.append(app)
                    seenPaths.insert(realURL)
                }
            }
        }
        
        // 最后只排序，不用再去重！
        let uniqueApps = foundApps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        return uniqueApps
    }
    
    static func getAppIcon(bundleID:String)->NSImage?{
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url) {
            
            var icon = NSImage(named: NSImage.applicationIconName)!
            if let appIconName = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String{
                if let appIcon = bundle.image(forResource: appIconName){
                    icon = appIcon
                }
            }
            return icon
        } else {
            return nil
        }
    }

    static func makeApp(from url: URL) -> MacApp? {
        guard let bundle = Bundle(url: url) else { return nil }

        let displayName = FileManager.default.displayName(atPath: url.path(percentEncoded: false))

        let name = displayName.hasSuffix(".app") || displayName.hasSuffix(".APP")
            ? String(displayName.dropLast(4))
            : displayName

        let bundleID = bundle.bundleIdentifier ?? "unknown"
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知"
        
        var icon = NSImage(named: NSImage.applicationIconName)!
        if let appIconName = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String{
            if let appIcon = bundle.image(forResource: appIconName){
                icon = appIcon
            }
        }
        
        return MacApp(
            name: name,
            bundleID: bundleID,
            version: version,
            path: url,
            icon: icon
        )
    }
}
extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}

extension FIFinderSyncController {
    
    /// 返回当前 Finder 操作的上下文信息
    /// - Returns: (folder: String, items: [String])
    ///   - folder: 用户当前关注的文件夹路径（选中多个文件时为其共同父文件夹，选中文件夹时为该文件夹本身，无选中时为 targetedURL）
    ///   - items: 当前选中的所有项的路径（无选中时返回 targetedURL 所在文件夹）
    static func currentContext() -> (folder: [String], items: [String]) {
        let controller = FIFinderSyncController.default()
        let selectedURLs = controller.selectedItemURLs() ?? []
        
        if !selectedURLs.isEmpty {
            // 有选中项
            let itemPaths = selectedURLs.map { $0.path }
            
            // 找到第一个选中项的父目录作为当前文件夹
            // 如果第一个是文件夹，就用它本身；否则用其父目录
            let firstURL = selectedURLs.first!
            let folderPath = firstURL.hasDirectoryPath
                ? firstURL.path
                : firstURL.deletingLastPathComponent().path
            
            return ([folderPath], itemPaths)
            
        } else {
            // 没有选中任何项，使用 targetedURL 作为文件夹（通常是右侧窗格当前显示的文件夹）
            let targetPath = controller.targetedURL()!.path
            return ([targetPath], [targetPath])
        }
    }
    
    // 方便调用：只想要文件夹路径
    static func getSelectedFolder() -> [String] {
        return currentContext().folder
    }
    
    // 方便调用：只想要选中项路径数组
    static func getSelectedItems() -> [String] {
        return currentContext().items
    }
}
