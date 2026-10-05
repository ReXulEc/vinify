import SwiftUI

@main
struct VinifyApp: App {
    @StateObject private var vinifyManager = VinifyManager()

    var body: some Scene {
        MenuBarExtra("Vinify", systemImage: "music.note") {
            Button("Ayarlar") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            
            Button("GitHub") {
                if let url = URL(string: "https://github.com/rexulec/vinify") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()
            
            Button("Çıkış") {
                NSApplication.shared.terminate(nil)
            }
        }
        
        Settings {
            VStack {
                Text("Kişiselleştirme Ayarları")
                    .font(.headline)
            }
            .frame(width: 300, height: 200)
        }
    }
}
