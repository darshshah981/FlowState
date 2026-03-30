import SwiftUI

@main
struct CadenceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra("Cadence", systemImage: appModel.menuBarSymbolName) {
            MenuContentView(appModel: appModel)
                .frame(width: 320, height: 520)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appModel: appModel)
                .padding(18)
                .frame(width: 420, height: 560)
                .background(FlowTheme.background)
        }
    }
}
