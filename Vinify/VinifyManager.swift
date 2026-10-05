import Foundation
import WidgetKit
import AppKit
import Combine

@MainActor
class VinifyManager: ObservableObject {
    @Published var updateCounter: Int = 0
    
    let appGroupID = "group.com.mert.vinifygroup"
    var timer: Timer?

    init() {
        updateSpotifyData()
        
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateSpotifyData()
            }
        }
    }
    
    func updateSpotifyData() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    set trkName to name of current track
                    set trkArtist to artist of current track
                    set artUrl to artwork url of current track
                    set pos to player position
                    set dur to duration of current track
                    return trkName & "|||" & trkArtist & "|||" & artUrl & "|||" & pos & "|||" & dur
                else
                    return "Duraklatıldı"
                end if
            end tell
        else
            return "Spotify Kapalı"
        end if
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            let resultString = result.stringValue ?? ""
            
            if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
                let components = resultString.components(separatedBy: "|||")
                
                if components.count == 5 {
                    sharedDefaults.set(components[0] + " - " + components[1], forKey: "currentTrack")
                    sharedDefaults.set(Double(components[3]) ?? 0, forKey: "currentPosition")
                    
                    let durationSec = (Double(components[4]) ?? 0) / 1000
                    sharedDefaults.set(durationSec, forKey: "trackDuration")
                    
                    if let url = URL(string: components[2]),
                       let imageData = try? Data(contentsOf: url) {
                        sharedDefaults.set(imageData, forKey: "artworkData")
                    }
                } else {
                    sharedDefaults.set(resultString, forKey: "currentTrack")
                }
            }
            
            updateCounter += 1
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
