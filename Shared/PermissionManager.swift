import Observation
import ServiceManagement
import SwiftUI
import OSLog

@Observable
final class PermissionManager {
    static let shared = PermissionManager()
    let extID: String
    let helperID: String

    private init() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("Bundle identifier not found")
        }
        self.extID = "\(bundleID).FinderPlusExt"
        self.helperID = "\(bundleID).FinderPlusHelper"
    }

    // MARK: - 可观察的存储属性
    var extensionEnabled = false
    
    var fullDiskAccessGranted = false
    
    var helperStatus: SMAppService.Status = .notRegistered
  
    var isHelperLoading = false
    
    var isFinderExtensionOnBinding: Binding<Bool> {
        Binding (get: {
            return Magic.isExtensionEnabled()
        }, set: { newValue in
            if newValue {
                self.extensionEnabled = Magic.enableFinderSyncExtension(self.extID)
            } else {
                self.extensionEnabled = !Magic.disableFinderSyncExtension(self.extID)
            }
        }
        )

    }

    // MARK: - 计算属性：是否“开启”
    private var isHelperOn: Bool {
        switch helperStatus {
        case .enabled, .requiresApproval:
            return true
        default:
            return false
        }
    }
    
    // MARK: - 可绑定版本（用于 Toggle）
    var isHelperOnBinding: Binding<Bool> {
        Binding(
            get: {
                return self.isHelperOn
            },
            set: { newValue in
                guard !self.isHelperLoading else { return }
                
                self.isHelperLoading = true
                
                // Wrap async calls in Task
                Task {
                    do {
                        if newValue {
                            await self.registHelper()
                        } else {
                            await self.unregisterHelper()
                        }
                    }
                    
                    // Always reset loading state when done (even if there's an error)
                    self.isHelperLoading = false
                }
            }
        )
    }


 
    // MARK: - 权限刷新
    func refreshPermission() async {
        async let extensionCheck = Task.detached { await Magic.isExtensionEnabled()}
        async let diskAccessCheck = Task.detached {  await Magic.refreshFullDiskAccessStatus() }
        async let helperStatusCheck = Task.detached {  await Magic.refreshRegistStatus(self.helperID) }
        
        self.extensionEnabled = await extensionCheck.value
        self.fullDiskAccessGranted = await diskAccessCheck.value
        self.helperStatus = await helperStatusCheck.value
    }
    
    // MARK: - 注册 Helper
    func registHelper() async {
        Magic.registHelper(helperID)
        // 注册后立即刷新状态（避免延迟）
        await refreshPermission()
    }
    
    // MARK: - 注销 Helper
    func unregisterHelper() async {
        Magic.unregisterHelper(helperID)
        await refreshPermission()
    }
}
