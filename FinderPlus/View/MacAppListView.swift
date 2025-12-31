//
//  SortOption.swift
//  FinderPlus
//
//  Created by 0x400 on 2025/12/30.
//


import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case name = "名称"
    case bundleID = "Bundle ID"
    case added = "安装"
    var id: String { self.rawValue }
}
struct CategorySectionView: View {
    let category: AppCategory
    let apps: [MacApp]
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(category.displayName)
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(apps,id: \.id) { app in
                HStack {
                    Image(nsImage: app.icon)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 2))

                    Text(app.name)
                        .font(.system(size: 15, weight: .medium))
                        .onTapGesture {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(app.name, forType: .string)
                        }

                    Spacer()

                    Button {
                        onRemove(app.bundleID)
                    } label: {
                        Label("", systemImage: "minus")
                            .labelStyle(.iconOnly)
                            .frame(height: 9)
                    }
                }
            }
        }
    }
}
// MARK: - 主视图
struct MacAppListView: View {
    @Environment(AppSettings.self) var settings
    @Binding var apps: [MacApp]
    @Binding var isShowingPresented: Bool
    @State private var searchText = ""
    @State private var copiedLabel:UUID? = nil
    @State private var sortBy :SortOption = .added
    private var addedAppsByCategory: (editor: [MacApp], terminal: [MacApp]) {
        let allBundleIDs = Dictionary(grouping: apps, by: \.bundleID)
        let editorIDs = Set(settings.supportedAppList[AppCategory.editor.rawValue] ?? [])
        let terminalIDs = Set(settings.supportedAppList[AppCategory.terminal.rawValue] ?? [])

        let editorApps = editorIDs.compactMap { bundleID in
            allBundleIDs[bundleID]?.first
        }.compactMap { $0 }

        let terminalApps = terminalIDs.compactMap { bundleID in
            allBundleIDs[bundleID]?.first
        }.compactMap { $0 }

        return (editorApps, terminalApps)
    }
    private var filteredAndUnaddedApps: [MacApp] {
        let addedBundleIDs = Set(
            (settings.supportedAppList[AppCategory.editor.rawValue] ?? []) +
            (settings.supportedAppList[AppCategory.terminal.rawValue] ?? [])
        )

        let unaddedApps = apps.filter { !addedBundleIDs.contains($0.bundleID) }

        if searchText.isEmpty {
            return unaddedApps
        } else {
            return unaddedApps.filter {
                $0.keywords.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
   
    private func addApp(_ app: String, to category: AppCategory) {
        @Bindable var bindableSettings = settings
        bindableSettings.supportedAppList[category.rawValue, default: []].append(app)
    }

    private func removeApp(_ app: String) {
        @Bindable var bindableSettings = settings
        for category in [AppCategory.editor, .terminal] {
            if let index = bindableSettings.supportedAppList[category.rawValue]?.firstIndex(of: app) {
                bindableSettings.supportedAppList[category.rawValue]?.remove(at: index)
                break
            }
        }
    }

    private func makeAppRow(for app: MacApp) -> some View {
        HStack {
            Image(nsImage: app.icon)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Text(app.name)
                .font(.system(size: 15, weight: .medium))
                .onTapGesture {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(app.name, forType: .string)
                }

            Spacer()

            Menu {
                ForEach(AppCategory.allCases, id: \.id) { category in
                    Button(category.displayName) {
                        addApp(app.bundleID, to: category)
                    }
                }
            } label: {
                Label("添加", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .menuIndicator(.hidden)
        }
    }
//    private func isAppAdded(_ bundleID: String) -> Bool {
//        let editorList = settings.supportedAppList[AppCategory.editor.rawValue] ?? []
//        let terminalList = settings.supportedAppList[AppCategory.terminal.rawValue] ?? []
//        return editorList.contains(bundleID) || terminalList.contains(bundleID)
//    }
//    var filteredApps: [MacApp] {
//        // 预计算所有已添加的 bundleID（提升性能）
//        let editorList = settings.supportedAppList[AppCategory.editor.rawValue] ?? []
//        let terminalList = settings.supportedAppList[AppCategory.terminal.rawValue] ?? []
//        let addedBundleIDs = Set(editorList + terminalList)
//
//        if searchText.isEmpty {
//            return apps
//        } else {
//            return apps.filter { app in
//                if addedBundleIDs.contains(app.bundleID) {
//                    return true // 已添加的永远显示
//                }
//                return app.keywords.localizedCaseInsensitiveContains(searchText)
//            }
//        }
// 
//    }
//    var sortedApps: [MacApp] {
//        let appsToSort = filteredApps // 先过滤搜索结果，再排序
//
//        switch sortBy {
//        case .added:
//            return appsToSort.sorted { a, b in
//                let aAdded = isAppAdded(a.bundleID)
//                let bAdded = isAppAdded(b.bundleID)
//                if aAdded != bAdded {
//                    return aAdded && !bAdded // 已添加的排前面
//                }
//                // 若“是否已添加”相同，则按名称排序（可自定义）
//                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
//            }
//
//        case .name:
//            return appsToSort.sorted {
//                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
//            }
//
//        case .bundleID:
//            return appsToSort.sorted {
//                $0.bundleID.localizedCaseInsensitiveCompare($1.bundleID) == .orderedAscending
//            }
//        }
//    }
//
//    func copyText(_ text:String){
//        NSPasteboard.general.clearContents()
//        NSPasteboard.general.setString(text, forType: .string)
//    }
//    
//    fileprivate func addApp(_ app: String, to category: AppCategory) {
//        @Bindable var bindableSettings = settings
//        if bindableSettings.supportedAppList[category.rawValue] != nil {
//            bindableSettings.supportedAppList[category.rawValue]?.append(app)
//        } else {
//            bindableSettings.supportedAppList[category.rawValue] = [app]
//        }
//    }
//    fileprivate func removeApp(_ app: String,) {
//        @Bindable var bindableSettings = settings
//        if let index =  (bindableSettings.supportedAppList[AppCategory.editor.rawValue] ?? []).firstIndex(of: app) {
//            bindableSettings.supportedAppList[AppCategory.editor.rawValue]?.remove(at: index)
//        } else if let index = (bindableSettings.supportedAppList[AppCategory.terminal.rawValue] ?? []).firstIndex(of: app) {
//            bindableSettings.supportedAppList[AppCategory.terminal.rawValue]?.remove(at: index)
//        }
//    }
    var body: some View {
        VStack{
            // 🔒 固定区域：已添加的 App（按分类）
            let (editorApps, terminalApps) = addedAppsByCategory
            if !editorApps.isEmpty || !terminalApps.isEmpty {
                HStack(alignment:.top){
                    if !editorApps.isEmpty {
                        CategorySectionView(category: .editor, apps: editorApps, onRemove: removeApp)
                    }
                    if !terminalApps.isEmpty {
                        CategorySectionView(category: .terminal, apps: terminalApps, onRemove: removeApp)
                    }
                }
            }

            // 📜 可滚动区域：未添加的 App
            List(filteredAndUnaddedApps) { app in
                makeAppRow(for: app)
            }
            
            .listStyle(.plain)
            .padding(0)
            .searchable(text: $searchText, prompt: "搜索 App 名称、Bundle ID…")

            Button("取消") {
                isShowingPresented = false
            }
            
        }
        .frame(height: 300)
        .padding()
         
        
    }
//    var body: some View {
//        @Bindable var bindableSettings = settings
//            List(sortedApps) { app in
//                HStack{
//                    Image(nsImage: app.icon).renderingMode(.original)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 16, height: 16)
//                    .clipShape(RoundedRectangle(cornerRadius: 2))
//                    
//                    
//                    Text(app.name)
//                        .font(.system(size: 15, weight: .medium))
//                        .onTapGesture(count: 1) {
//                            copyText(app.name)
//                        }
//                    
//                    Spacer()
//                    if isAppAdded(app.bundleID) {
//                        Button{
//                            removeApp(app.bundleID)
//                        } label: {
//                            Label("", systemImage: "minus")
//                                .labelStyle(.iconOnly)
//                                .frame(height:9)
//                        }
//                    } else {
//                        Menu {
//                            ForEach(AppCategory.allCases,id: \.id) { category in
//                                Button(category.displayName ){
//                                    addApp(app.bundleID, to: category)
//                                }
//                            }
//                        } label: {
//                            Label("添加", systemImage: "plus")
//                                .labelStyle(.iconOnly)
//                        }
//                        
//                        .menuIndicator(.hidden)
//                    }
//                }
//            }
//            
//        .searchable(text: $searchText, prompt: "搜索 App 名称、Bundle ID、版本…")
//         .padding(0)
//        .frame( height: 400)
//        Button("取消"){
//            isShowingPresented = false
//        }
//    }
//

}

#Preview {
    @Previewable @State var apps:[MacApp] = []
    @Previewable @State var isShowing = true
    MacAppListView(apps: $apps, isShowingPresented: $isShowing)
        .task{
            await apps = Magic.loadAllApps()
        }
        .environment(AppSettings.shared)
        
}

