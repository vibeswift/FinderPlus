import SwiftUI
import Foundation

struct AboutView:View{
    var body:some View{
        VStack(alignment: .trailing ){
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            Text("Github: [VibeSwift](https://github.com/vibeswift/FinderPlus)")
                    .font(.caption)
                    .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    AboutView()
}
