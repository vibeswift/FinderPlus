import SwiftUI
import ServiceManagement

// 权限状态
struct PermissionView: View {
    let permissionManager = PermissionManager.shared
    @State private var isRefreshing = false
    
    var body: some View {
        HStack {
            Group {
                StatusSection(permission: .ext())
                    .environment(permissionManager)
                StatusSection(permission: .fda())
                    .environment(permissionManager)
                StatusSection(permission: .helper())
                    .environment(permissionManager)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if !isRefreshing {
                    refreshPermissions()
                }
            }
            .onAppear {
                refreshPermissions()
            }
        }
        .padding()
    }
    
    private func refreshPermissions() {
        guard !isRefreshing else {return }
        
        isRefreshing = true
        Task {
            await permissionManager.refreshPermission()
            // 防止连续切换
           // try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            isRefreshing = false
        }
    }
}

struct PermissionStatus {
    let color: Color
    let text: LocalizedStringResource
}

struct Permission {
    let targert: String
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let alertTitle: LocalizedStringResource = "修改系统权限"
    let alertContent: LocalizedStringResource
    var hasSwitch: Bool = false
    let granted: PermissionStatus
    let denied: PermissionStatus
    var requiresApproval: PermissionStatus? = nil

    static func ext() -> Permission {
        Permission(
            targert: "extension",
            title: "访达扩展",
            description: "成功注册扩展后，访达工具栏右键选择“自定义工具栏”，将 FinderPlus 的图标拖入工具栏。",
            alertContent:  "点击确认跳转到系统设置修扩展权限，如关闭权限后再开启需要重新添加工具栏图标。",
            hasSwitch: true,
            granted: PermissionStatus(color: .green, text: "已注册"),
            denied: PermissionStatus(color: .red, text:"未注册")
        )
    }
    
    static func fda() -> Permission {
        Permission(
            targert: "files",
            title: "完全磁盘访问",
            description:  "开启完全磁盘访问权限后才能在外接硬盘等位置显示右键菜单，需手动去系统设置里开启。",
            alertContent:  "点击确认跳转到系统设置修改“完全磁盘访问权限”。",
            granted: PermissionStatus(color: .green, text:"已注册"),
            denied: PermissionStatus(color: .red, text:"未注册")
        )
    }
    
    static func helper() -> Permission {
        Permission(
            targert: "login",
            title: "助手程序",
            description:  "助手程序运行在后台，随用户登录启动，取消注册后新建文件等将无效。取消注册后进程自动退出。",
            alertContent:  "点击确认跳转到系统设置修改”App 后台活动“权限。",
            hasSwitch: true,
            granted: PermissionStatus(color: .green, text:  "已注册"),
            denied: PermissionStatus(color: .red, text:  "未注册"),
            requiresApproval: PermissionStatus(color: .yellow, text:"未开启")
        )
    }
}

struct StatusSection: View {
    @Environment(PermissionManager.self) private var permissionManager
    let permission: Permission
    @State private var showAlert = false
    
    // Extract status computation to computed property for clarity
    private var currentStatus: PermissionStatus {
        switch permission.targert {
        case "login":
            switch permissionManager.helperStatus {
            case .enabled:
                return permission.granted
            case .requiresApproval:
                return permission.requiresApproval ?? permission.denied
            case .notFound, .notRegistered:
                return permission.denied
            default:
                return permission.denied
            }
            
        case "extension":
            return permissionManager.extensionEnabled ? permission.granted : permission.denied
            
        case "files":
            return permissionManager.fullDiskAccessGranted ? permission.granted : permission.denied
            
        default:
            return permission.denied
        }
    }
    
    // Extract binding to avoid @Bindable in view body
    private var toggleBinding: Binding<Bool>? {
        if permission.hasSwitch {
            if permission.targert == "login" {
                return permissionManager.isHelperOnBinding
            } else {
                return permissionManager.isFinderExtensionOnBinding
            }
        } else {
            return  nil
        }
    }
    
    private var finderExtensionToggleBinding: Binding<Bool>? {
        permission.hasSwitch ? permissionManager.isFinderExtensionOnBinding : nil
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(currentStatus.color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            Text(permission.title)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if let binding = toggleBinding {
                Toggle("", isOn: binding)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
        }
        .contentShape(Rectangle())
        .help(permission.description)
        .onTapGesture(count: 1) {
            showAlert = true
        }
        .alert(permission.alertTitle, isPresented: $showAlert) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .confirm) {
                Magic.openSystemPreferences(settingName: permission.targert)
            }
        } message: {
            Text(permission.alertContent)
        }
        .padding(5)
        .background(Color.mainBg)
        .clipShape(.rect(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.mainBorder, lineWidth: 1)
        )
    }
}

#Preview {
    PermissionView()
        .environment(PermissionManager.shared)
}
