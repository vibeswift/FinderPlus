import SwiftUI
 
struct SettingView:View{
    @Environment(AppSettings.self) var settings
    

    var body:some View{
        @Bindable var bindableSettings = settings
        VStack(alignment: .leading,spacing: 0 ) {
            Divider()
            MenuItemsView()
            HStack{
                PermissionView()
                Spacer()
                AboutView()
            }
        }
        .toolbar {
            ToolbarItem(placement:.principal ) {
                Text("FinderPlus")
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}


#Preview {
    SettingView()
        .environment(AppSettings.shared)
}
