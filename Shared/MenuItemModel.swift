import Foundation
import SwiftUI

struct AppRelated:Codable,Hashable {
    let name:String
    let bundleID:String
}


struct MenuItem: Codable, Identifiable ,Equatable{
    var id = UUID()
    var index:Int = 0
    var title:LocalizedStringResource
    var icon: String
    var isEnabled: Bool = true
    var action:String
    var isToolbarEnabled:Bool = true
    var isContextEnabled:Bool = true
    var conditions: Set<Condition> = []
    var appBundleID:String?
    var appName:String?
    var appCategory:String?
}

extension MenuItem {
    static let aboutItem = MenuItem(title: "FinderPlus", icon: "info.circle"  ,action: "show")
    static let defaults: [MenuItem] = [
        MenuItem(index:99 ,title: "FinderPlus", icon: "info.circle",action: "show",)
    ]
    static let defaultsF = [
        MenuItem(title: "搜索文件", icon: "magnifyingglass",action:"search",conditions: [.folderOnly,.singleOnly]),
        MenuItem(title: "复制路径", icon: "document.on.document", action: "copypath"),
        MenuItem(title: "用软件打开",icon: "square.grid.2x2",action:"open"),
        MenuItem(title: "新建文件", icon: "doc.badge.plus", action:"new"),
        MenuItem(title: "FinderPlus", icon: "info.circle",action: "show")
    ]
}


enum Condition: String, Codable, Hashable {
    // 选中数量相关
    case singleOnly          // 仅单选
    case multipleOnly        // 仅多选（≥2）
    case singleOrBlankOnly   // 单选或空白处（selectedURLs.count <= 1）
    
    // 文件类型相关
    case folderOnly          // 仅文件夹
    case fileOnly            // 仅文件（非文件夹）
//    case imageOnly           // 仅图片
//    case videoOnly           // 仅视频
//    case codeOnly            // 仅代码文件
//    case archiveOnly         // 仅压缩包
    
//    // 磁盘类型相关
//    case externalVolumeOnly // 仅外置磁盘（U盘、移动硬盘、NAS）
//    case internalVolumeOnly  // 仅内置磁盘
//    
//    // 其他自定义
//    case hasExtension(String)  // 动态扩展名，比如 .swift, .pdf
//    case pathContains(String)  // 路径包含某字符串
}
