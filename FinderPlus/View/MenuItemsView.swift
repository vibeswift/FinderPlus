import SwiftUI
import UniformTypeIdentifiers
import SwiftUIIntrospect

enum AppType: String { case editor, terminal }

struct SupportedApps {
    var editor: [MacApp]
    var terminal: [MacApp]
}

struct MenuItemsView: View {
    @Environment(AppSettings.self) var settings
    @State private var showResetAlert = false
    @State private var apps: [MacApp] = []
    @State private var selection:UUID?
    @State private var draggingID:UUID?
    @State private var dragOffset: CGSize = .zero
    @FocusState private var focusedID: UUID?
    //@State private var supportedApps = SupportedApps(editor: [], terminal: [])
    private var supportedApps: SupportedApps {
        let editorBundles = settings.supportedAppList[AppCategory.editor.rawValue] ?? []
        let terminalBundles = settings.supportedAppList[AppCategory.terminal.rawValue] ?? []
        return SupportedApps(
            editor: apps.filter { editorBundles.contains($0.bundleID) },
            terminal: apps.filter { terminalBundles.contains($0.bundleID) }
        )
    }
    fileprivate func removeMenuItem() {
        
        @Bindable var bindableSettings = settings
        
        if let index = bindableSettings.menuItems.firstIndex(where: { $0.id == selection }) {
            
            bindableSettings.menuItems.remove(at: index)
            
            if bindableSettings.menuItems.isEmpty {
                selection = nil
            } else if index == 0 {
                selection = bindableSettings.menuItems[index].id
            } else {
                selection = bindableSettings.menuItems[index-1].id
            }
        }
    }
 
    var body: some View {
        
        @Bindable var bindableSettings = settings
        
        VStack(spacing:0){
            HStack {
                Text("菜单名称").frame( alignment: .leading)
                Spacer()
                Group{
                    Text("工具栏")
                    Text("右键")
                    Text("启用")
                }.frame(width:50,alignment:.center)
            }
            .foregroundColor(.secondary)
            .padding([.leading,.trailing])
            .frame(height: 30)
            
            Divider().overlay(Color.mainBorder)
            
            ScrollView{
                VStack(spacing:0){
                    ForEach($bindableSettings.menuItems,id:\.id) { $item in
                        HStack {
                            Image(systemName: item.icon)
                                .foregroundStyle(.tint)
                                .frame(width: 20)
                            switch item.action {
                            case "open":
                                if let appName = item.appName {
                                    Text("用\(appName)打开")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text("用软件打开")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                let pickerApps = item.appCategory == "editor" ? supportedApps.editor :supportedApps.terminal
                                Picker("", selection:$item.appBundleID) {
                                    ForEach(pickerApps, id: \.id) { app in
                                        HStack{
                                            Image(nsImage: app.icon.resized(to: NSSize(width: 16, height: 16)))
                                            Text(app.name)
                                        }.tag(app.bundleID)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(PopUpButtonPickerStyle())
                                .padding(0)
                                .onChange(of:item.appBundleID) {_,newBundleID in
                                    if let selectedApp = pickerApps.first(where: { $0.bundleID == newBundleID }) {
                                        item.appName = selectedApp.name
                                    }
                                }
                            default:
                                Text( item.title )
                                Spacer()
                            }
                            

                            Group{
                                Toggle("", isOn: $item.isToolbarEnabled)
                                Toggle("", isOn: $item.isContextEnabled)
                                Toggle("", isOn: $item.isEnabled)
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                            }
                            .frame(width: 50)
                            .labelsHidden()
                        }
                        .contentShape(Rectangle())
                        .padding([.leading,.trailing])
                        .frame(height: 30)
                        .background(
                            selection == item.id
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear
                        )
                        .onTapGesture {
                            focusedID = nil
                            selection = item.id
                        }
                        .opacity(draggingID == item.id ? 0 : 1)
                        .onDrag {
                            selection = item.id
                            withAnimation {
                                draggingID = item.id
                            }
                            return  NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: ItemDropDelegate(
                                itemID: item.id,
                                draggingID: $draggingID,
                                menuItems: $bindableSettings.menuItems
                            )
                        )
                        Divider().overlay(Color.mainBorder)
                    }
                }
            }
            .introspect(.scrollView, on: .macOS(.v26)) { scrollView in
                scrollView.scrollerStyle = .overlay
            }
            .onDrop(
                of: [UTType.plainText],
                delegate: ScrollViewDropDelegate(draggingID: $draggingID)
            )
            .task{
                await apps = Magic.loadAllApps()
            }
//            .onChange(of: apps) { _, newApps in
//                supportedApps.editor = newApps.filter { (bindableSettings.supportedAppList[AppCategory.editor.rawValue] ?? []).contains($0.bundleID) }
//                supportedApps.terminal =  newApps.filter { (bindableSettings.supportedAppList[AppCategory.terminal.rawValue] ?? []).contains($0.bundleID) }
//            }
//            .onChange(of: settings.supportedAppList) { _, _ in
//                // 注意：这里不能直接写 settings，因为 @Environment 不是 Equatable
//                // 所以需要监听具体字段
//            }
            Divider().overlay(Color.mainBorder)
            
            HStack(alignment: .center){
                MenuSelectorView(apps:$apps,selection:$selection)
                
                Button{
                    removeMenuItem()
                } label: {
                    Label("", systemImage: "minus")
                        .labelStyle(.iconOnly)
                        .frame(height:9)
                }
                .disabled(selection == nil ? true : false)

                Spacer()

                Button("重置") {
                    showResetAlert = true
                }
                .controlSize(.small)
                .alert("确认重置？", isPresented: $showResetAlert) {
                    Button("取消", role: .cancel) {}
                    Button("确定", role: .destructive) {
                        settings.resetMenuItems()
                    }
                } message: {
                    Text("所有菜单将被删除。")
                }
            }
            .padding([.leading,.trailing])
            .frame(height: 30)
        }
        .background(Color.mainBg)
        .clipShape(.rect(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.mainBorder, lineWidth: 1))
        .padding([.top, .leading,.trailing])
        .onTapGesture() {
            focusedID = nil
            selection = nil
        }
    }
}

struct ItemDropDelegate: DropDelegate {
    let itemID: UUID
    @Binding var draggingID: UUID?
    @Binding var menuItems :[MenuItem]
    func dropEntered(info: DropInfo) {
        guard let provider = info.itemProviders(for: [.plainText]).first else {
            return
        }

        provider.loadItem(
            forTypeIdentifier: UTType.plainText.identifier,
            options: nil
        ) { data, _ in
            guard
                let data = data as? Data,
                let uuidString = String(data: data, encoding: .utf8),
                let fromID = UUID(uuidString: uuidString),
                let fromIndex = menuItems.firstIndex(where: { $0.id == fromID }),
                let toIndex = menuItems.firstIndex(where: { $0.id == itemID }),
                fromIndex != toIndex
            else { return }
            
            withAnimation {
                menuItems.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        }
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
}

struct ScrollViewDropDelegate: DropDelegate {
    @Binding var draggingID: UUID?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        // 禁用加号
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
}


#Preview {
    MenuItemsView()
        .environment(AppSettings.shared)
}
