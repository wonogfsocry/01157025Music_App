//
//  ContentView.swift
//  01157025Music_App
//
//  Created by user10 on 2025/1/3.
//
import SwiftUI
import AVFoundation

struct MusicPlayerView: View {
    @State private var player: AVPlayer = AVPlayer()
    @State private var isPlaying = false
    @State private var currentTrackIndex = 0
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 1
    @State private var isShuffle = false
    @State private var repeatMode: RepeatMode = .off
    @State private var volume: Float = 0.5
    @State private var isSeeking = false // 新增狀態變數
    @State private var showTrackList = false // 新增：控制歌曲清單顯示狀態
    
    let tracks = [
            ("呼吸のように", "photo1"), // 替換為你的歌曲和對應圖片名稱
            ("裸の勇者", "photo2"),
            ("踊り子", "photo3"),
            ("不可幸力", "photo4"),
            ("東京フラッシュ", "photo5"),
            ("CHAINSAW BLOOD", "photo6")
        ]
    
    var body: some View {
        ZStack{
            Image(.background)
                .resizable()
                .scaledToFit()
            VStack {
                // Track info
                VStack {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill") // 喇叭圖標
                            .foregroundColor(.gray)
                            .font(.title2)
                            .padding(.trailing, 8)
                        Slider(value: $volume, in: 0...1) {_ in
                            updateVolume()
                        }
                        .accentColor(.gray)
                    }
                }
                .padding([.top, .leading, .trailing], 30.0)
                VStack {
                    Text("\(tracks[currentTrackIndex].0)")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                        .shadow(color: .black, radius: 2)
                        .padding(.bottom, 20)
                }
                Spacer()
                
                // Playback controls
                HStack(spacing: 40) {
                    CircleButton(iconName: "backward.fill", action: {
                        previousTrack()
                    })
                    CircleButton(iconName: isPlaying ? "pause.fill" : "play.fill", action: {
                        togglePlayPause()
                    })
                    CircleButton(iconName: "forward.fill", action: {
                        nextTrack()
                    })
                }
                .padding(.bottom, 30)
                
                // Progress bar
                VStack {
                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(totalTime))
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.bottom, -10.0)
                    Slider(value: $currentTime, in: 0...totalTime, onEditingChanged: { editing in
                        isSeeking = editing
                        if !editing {
                            player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                        }
                    })
                    .padding()
                }
                .padding()
                .padding(.bottom, -10.0)
                
                // Shuffle and repeat
                HStack {
                    Button(action: toggleShuffle) {
                        Image(systemName: isShuffle ? "shuffle.circle.fill" : "shuffle.circle")
                            .foregroundStyle(Color.gray.opacity(0.8))
                            .font(.title)
                    }
                    Spacer()
                    Button(action: toggleRepeatMode) {
                        Image(systemName: repeatMode.imageName)
                            .foregroundStyle(Color.gray.opacity(0.8))
                            .font(.title)
                    }
                    Spacer()
                    Button(action: { showTrackList.toggle() }) { // 顯示歌曲清單按鈕
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Color.gray.opacity(0.8))
                            .font(.title)
                    }
                }
                .padding(.horizontal, 30.0)
                .padding(.bottom, 10.0)
            }
            .sheet(isPresented: $showTrackList) { // 彈出歌曲清單
                TrackListView(tracks: tracks, currentTrackIndex: $currentTrackIndex, onSelect: { index in
                    currentTrackIndex = index
                    setupPlayer()
                    player.play()
                    isPlaying = true
                })
            }
            .onAppear {
                setupPlayer()
            }
        }
    }
    
    func setupPlayer() {
            guard let url = Bundle.main.url(forResource: tracks[currentTrackIndex].0, withExtension: "mp3") else { return }
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            player.volume = volume
            
            // Track duration and time observer
            totalTime = item.asset.duration.seconds.isNaN ? 0 : item.asset.duration.seconds
            player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { time in
                if !isSeeking {
                    currentTime = time.seconds
                }
                if time.seconds >= totalTime - 1, repeatMode != .single {
                    nextTrack()
                }
            }
        }
    
    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func nextTrack() {
        currentTrackIndex = isShuffle ? Int.random(in: 0..<tracks.count) : (currentTrackIndex + 1) % tracks.count
        setupPlayer()
        player.play()
    }
    
    func previousTrack() {
        currentTrackIndex = currentTrackIndex == 0 ? tracks.count - 1 : currentTrackIndex - 1
        setupPlayer()
        player.play()
    }
    
    func toggleShuffle() {
        isShuffle.toggle()
    }
    
    func toggleRepeatMode() {
        repeatMode = repeatMode.next()
    }
    
    func sliderChanged(_ editing: Bool) {
        if editing {
            player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
        }
    }
    
    func updateVolume() {
        player.volume = volume
    }
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum RepeatMode {
    case off, all, single
    
    var imageName: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat.1"
        case .single: return "repeat.circle.fill"
        }
    }
    
    func next() -> RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .single
        case .single: return .off
        }
    }
}

struct CircleButton: View {
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 55, height: 55)
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.title)
            }
        }
    }
}


struct TrackListView: View {
    let tracks: [(String, String)]
    @Binding var currentTrackIndex: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        NavigationView {
            VStack{
                List(tracks.indices, id: \.self) { index in
                    Button(action: {
                        onSelect(index)
                    }) {
                        HStack {
                            Text("\(tracks[index].0)")
                                .foregroundStyle(index == currentTrackIndex ? Color.black.opacity(0.8) : Color.gray.opacity(0.8))
                                .padding()
                            Spacer()
                            Spacer()
                            Image(tracks[index].1)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .padding()
                            Spacer()
                            if index == currentTrackIndex {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Song List")
                            .font(.title)
                            .foregroundColor(.white)
                            .bold()
                            .shadow(color: .black, radius: 2)
                            .padding(.bottom, -10.0)
                    }
                }
            }
        }
    }
}

#Preview {
    MusicPlayerView()
}
