import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let appGroupID = "group.com.mert.vinifygroup"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), track: "Elimde Yalanlarla", artist: "90 BPM", artwork: nil, position: 88, duration: 277, isPlaying: true, startDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let entry = await fetchEntry()
            completion(Timeline(entries: [entry], policy: .never))
        }
    }
    
    func fetchEntry() async -> SimpleEntry {
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        let fullTrack = sharedDefaults?.string(forKey: "currentTrack") ?? "Veri Bekleniyor... - "
        
        // Şarkı adı ve sanatçıyı " - " karakterine göre ayırıyoruz
        let components = fullTrack.components(separatedBy: " - ")
        let track = components.first ?? "Bilinmeyen Şarkı"
        let artist = components.dropFirst().joined(separator: " - ")
        
        let position = sharedDefaults?.double(forKey: "currentPosition") ?? 0
        let duration = sharedDefaults?.double(forKey: "trackDuration") ?? 100
        let isPlaying = sharedDefaults?.bool(forKey: "isPlaying") ?? false
        let artworkURLStr = sharedDefaults?.string(forKey: "artworkURL") ?? ""
        
        let startDate = Date(timeIntervalSinceNow: -position)
        var nsImage: NSImage? = nil
        
        if let url = URL(string: artworkURLStr) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = NSImage(data: data) {
                    nsImage = image
                }
            } catch {
                print("Görsel indirilemedi")
            }
        }
        
        return SimpleEntry(date: Date(), track: track, artist: artist.isEmpty ? "Spotify" : artist, artwork: nsImage, position: position, duration: duration, isPlaying: isPlaying, startDate: startDate)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let track: String
    let artist: String
    let artwork: NSImage?
    let position: Double
    let duration: Double
    let isPlaying: Bool
    let startDate: Date
}

struct VinifyWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        HStack(spacing: 14) {
            if let image = entry.artwork {
                if renderingMode == .fullColor {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 3)
                } else {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .luminanceToAlpha()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 90, height: 90)
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray).font(.title))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.track)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(entry.artist)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                VStack(spacing: 4) {
                    ProgressView(value: max(0, entry.position), total: max(1, entry.duration))
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(.primary)
                        .widgetAccentable()
                    
                    HStack {
                        if entry.isPlaying {
                            Text(entry.startDate, style: .timer)
                        } else {
                            Text(formatTime(entry.position))
                        }
                        Spacer()
                        Text(formatTime(entry.duration))
                    }
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .containerBackground(.background, for: .widget)
    }
    
    func formatTime(_ seconds: Double) -> String {
        if seconds.isNaN || seconds.isInfinite { return "0:00" }
        let totalSeconds = Int(seconds)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

@main
struct VinifyWidget: Widget {
    let kind: String = "VinifyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VinifyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vinify Müzik Çalar")
        .description("Şu an çalan müziği ve albüm kapağını gösterir.")
        .supportedFamilies([.systemMedium]) // TODO: küçük için de ekle
    }
}
