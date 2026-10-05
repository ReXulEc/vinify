import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let appGroupID = "group.com.mert.vinifygroup"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), track: "Şarkı - Sanatçı", artwork: nil, position: 0, duration: 100)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [getEntry()], policy: .never)
        completion(timeline)
    }
    
    func getEntry() -> SimpleEntry {
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        let track = sharedDefaults?.string(forKey: "currentTrack") ?? "Veri Bekleniyor..."
        

        let position = sharedDefaults?.double(forKey: "currentPosition") ?? 0
        let duration = sharedDefaults?.double(forKey: "trackDuration") ?? 100
        let artworkData = sharedDefaults?.data(forKey: "artworkData")
        
        var nsImage: NSImage? = nil
        if let data = artworkData { nsImage = NSImage(data: data) }
        
        return SimpleEntry(date: Date(), track: track, artwork: nsImage, position: position, duration: duration)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let track: String
    let artwork: NSImage?
    let position: Double
    let duration: Double
}

struct VinifyWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                if let image = entry.artwork {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                } else {
                    Image(systemName: "music.note.list")
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .foregroundColor(.gray)
                }
                
                // Şarkı Adı
                Text(entry.track)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // İlerleme Çubuğu ve Zamanlar
            VStack(spacing: 6) {
                ProgressView(value: max(0, entry.position), total: max(1, entry.duration))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                
                HStack {
                    Text(formatTime(entry.position))
                    Spacer()
                    Text(formatTime(entry.duration))
                }
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
            }
        }
        .padding()
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
        .configurationDisplayName("Spotify Durumu")
        .description("Spotify'da şu an çalan şarkıyı gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
