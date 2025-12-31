import SwiftUI

struct MenuSelectorView: View {
    @Environment(AppSettings.self) var settings
    @Binding var apps:[MacApp]
    @Binding var selection: UUID?
    @State private var isShowingSheet = false
    
    
    private var supportedEditorApps: [MacApp] {
        let ids = settings.supportedAppList[AppCategory.editor.rawValue] ?? []
        return apps.filter { ids.contains($0.bundleID) }
    }

    private var supportedTerminalApps: [MacApp] {
        let ids = settings.supportedAppList[AppCategory.terminal.rawValue] ?? []
        return apps.filter { ids.contains($0.bundleID) }
    }
    
    fileprivate func insertMenuItem(_ item:MenuItem, with app:MacApp? = nil, category:String? = nil) {
        
        @Bindable var bindableSettings = settings
        
        var newItem = item
        newItem.id = UUID()
        
        if let app = app {
            newItem.appName = app.name
            newItem.appBundleID = app.bundleID
            newItem.appCategory = category
        }
        
        if let selection = selection,
           let index = bindableSettings.menuItems.firstIndex(where: { $0.id == selection }) {
            bindableSettings.menuItems.insert(newItem, at:index+1)
        } else if !bindableSettings.menuItems.isEmpty{
            bindableSettings.menuItems.insert(newItem, at:bindableSettings.menuItems.count-1 )
        } else {
            bindableSettings.menuItems.append(newItem)
        }
        
        selection = newItem.id
    }
    
    var body: some View {
        
        @Bindable var bindableSettings = settings

        let supportedEditors = supportedEditorApps
        let supportedTerminals = supportedTerminalApps
        Menu {
            ForEach(MenuItem.defaultsF,id: \.id) { item in
                switch item.action {
                case "open":
                    Menu{
                        if supportedEditors.isEmpty,supportedTerminals.isEmpty {
                            Text("未安装支持的软件")
                        } else {
                            if !supportedEditors.isEmpty{
                                Text("编辑").font(.caption)
                                ForEach(supportedEditors, id: \.id) { app in
                                    Button{
                                        insertMenuItem(item,with: app,category:"editor")
                                    } label: {
                                        Label{
                                            Text(app.name)
                                        } icon:{
                                            Image(nsImage: app.icon.resized(to: NSSize(width: 16, height: 16)))
                                        }
                                    }
                                }
                            }
                            if !supportedTerminals.isEmpty{
                                Text("终端").font(.caption)
                                ForEach(supportedTerminals, id: \.id) { app in
                                    Button{
                                        insertMenuItem(item,with: app,category:"terminal")
                                    } label: {
                                        Label{
                                            Text(app.name)
                                        } icon:{
                                            Image(nsImage: app.icon.resized(to: NSSize(width: 16, height: 16)))
                                        }
                                    }
                                }
                            }
                        }
                        Button{
                            isShowingSheet.toggle()
                        } label: {
                            Text("+")
                        }
                    } label: {
                        Label( item.title ,systemImage: item.icon)
                    }

                default:
                    Button{
                        insertMenuItem(item)
                    } label: {
                        Label( item.title ,systemImage: item.icon)
                    }
                }
            }
               
        } label: {
            Label("添加", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .sheet(isPresented: $isShowingSheet) {
            MacAppListView(apps: $apps,isShowingPresented: $isShowingSheet)
        }
    }
}
//
//#Preview {
//    @Previewable @State var apps:[MacApp] = []
//    @Previewable @State var selection:UUID? = nil
//    MenuSelectorView( apps: $apps,selection: $selection)
//         .environment(AppSettings.shared)
//         .task{
//             await apps = Magic.loadAllApps()
//         }
//}
