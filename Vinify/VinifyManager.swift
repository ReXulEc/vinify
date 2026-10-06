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
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in self.updateSpotifyData() }
        }
    }
    
    func updateSpotifyData() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                set pState to player state as string
                if pState is "playing" or pState is "paused" then
                    set trkName to name of current track
                    set trkArtist to artist of current track
                    try
                        set artUrl to artwork url of current track
                    on error
                        set artUrl to "NONE"
                    end try
                    set pos to player position
                    set dur to duration of current track
                    return trkName & "|||" & trkArtist & "|||" & artUrl & "|||" & pos & "|||" & dur & "|||" & pState
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
                
                if components.count == 6 {
                    let newTrack = components[0] + " - " + components[1]
                    let posStr = components[3].replacingOccurrences(of: ",", with: ".")
                    let durStr = components[4].replacingOccurrences(of: ",", with: ".")
                    let newPosition = Double(posStr) ?? 0
                    let newDuration = (Double(durStr) ?? 0) / 1000
                    let newIsPlaying = (components[5] == "playing")
                    
                    var newURLString = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    if newURLString != "NONE" {
                        if newURLString.hasPrefix("spotify:image:") {
                            newURLString = newURLString.replacingOccurrences(of: "spotify:image:", with: "https://i.scdn.co/image/")
                        } else {
                            newURLString = newURLString.replacingOccurrences(of: "http://", with: "https://")
                        }
                    } else {
                        newURLString = ""
                    }
                    
                    // Önceki verileri çekiyoruz
                    let oldTrack = sharedDefaults.string(forKey: "currentTrack") ?? ""
                    let oldIsPlaying = sharedDefaults.bool(forKey: "isPlaying")
                    let oldPosition = sharedDefaults.double(forKey: "currentPosition")
                    let lastUpdateDate = sharedDefaults.object(forKey: "lastUpdateDate") as? Date ?? Date()
                    
                    var needsReload = false
                    
                    if oldTrack != newTrack || oldIsPlaying != newIsPlaying {
                        needsReload = true
                    } else if newIsPlaying {
                        let elapsed = Date().timeIntervalSince(lastUpdateDate)
                        let expectedPosition = oldPosition + elapsed
                        
                        if abs(newPosition - expectedPosition) > 3.0 {
                            needsReload = true
                        }
                    } else {
                        if abs(newPosition - oldPosition) > 1.0 {
                            needsReload = true
                        }
                    }
                    
                    if needsReload {
                        sharedDefaults.set(newTrack, forKey: "currentTrack")
                        sharedDefaults.set(newPosition, forKey: "currentPosition")
                        sharedDefaults.set(newDuration, forKey: "trackDuration")
                        sharedDefaults.set(newIsPlaying, forKey: "isPlaying")
                        if newURLString.isEmpty {
                            sharedDefaults.removeObject(forKey: "artworkURL")
                        } else {
                            sharedDefaults.set(newURLString, forKey: "artworkURL")
                        }
                        
                        sharedDefaults.set(Date(), forKey: "lastUpdateDate")
                        
                        updateCounter += 1
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                } else {
                    let currentStatus = sharedDefaults.string(forKey: "currentTrack")
                    if currentStatus != resultString {
                        sharedDefaults.set(resultString, forKey: "currentTrack")
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
    }
}
