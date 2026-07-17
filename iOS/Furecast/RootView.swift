import SwiftUI

struct RootView: View {
    @AppStorage("furecast.theme") private var themeRaw = AppTheme.system.rawValue

    var body: some View {
        HomeView()
            .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
            .tint(FurecastColor.coral)
    }
}
