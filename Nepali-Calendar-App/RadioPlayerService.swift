//
//  RadioPlayerService.swift
//  Nepali-Calendar-App
//
//  Streams live Nepali FM radio using AVPlayer.
//  Manages playback state, volume, and Now Playing info.
//
//  Streams powered by Zeno.fm (zeno.fm) — a legal streaming platform
//  with ASCAP/BMI/SESAC licensing agreements and an official API
//  program supporting 50K+ radio stations in third-party apps.
//
//  Non-Zeno sources:
//  • Radio Kantipur — ekantipur.com (Kantipur Media Group)
//  • Hits FM 91.2 — fastcast4u.com relay
//

import Foundation
import AVFoundation
import Observation
import MediaPlayer

// MARK: - Model

struct RadioStation: Identifiable, Equatable {
    let id: String
    let name: String
    let nameNepali: String
    let frequency: String
    let streamURL: URL
}

// MARK: - Playback State

enum RadioPlaybackState: Equatable {
    case idle
    case loading
    case playing
    case error(String)
}

// MARK: - Service

@Observable
final class RadioPlayerService {

    static let shared = RadioPlayerService()

    // Published state
    var playbackState: RadioPlaybackState = .idle
    var currentStation: RadioStation?
    var volume: Float = 0.7

    /// IDs of last 3 played stations, most recent first.
    var recentStationIDs: [String] = UserDefaults.standard.stringArray(forKey: "recentRadioStations") ?? []

    /// Recently played stations (resolved from IDs, max 3).
    var recentStations: [RadioStation] {
        recentStationIDs.compactMap { id in stations.first { $0.id == id } }
    }

    /// All available stations.
    /// `name` = official Nepali name, `nameNepali` = English/romanized name.
    let stations: [RadioStation] = [

        // ── लोकप्रिय (Popular) ──────────────────────────────────

        RadioStation(
            id: "kantipur",
            name: "रेडियो कान्तिपुर",
            nameNepali: "Radio Kantipur",
            frequency: "96.1 MHz",
            streamURL: URL(string: "https://radio-broadcast.ekantipur.com/stream")!
        ),
        RadioStation(
            id: "ujyaalo",
            name: "उज्यालो ९० नेटवर्क",
            nameNepali: "Ujyaalo 90 Network",
            frequency: "90.0 MHz",
            streamURL: URL(string: "https://stream.zeno.fm/h527zwd11uquv")!
        ),
        RadioStation(
            id: "hitsfm",
            name: "हिट्स एफएम",
            nameNepali: "Hits FM",
            frequency: "91.2 MHz",
            streamURL: URL(string: "https://stream.zeno.fm/pw12mk36f18uv")!
        ),

        // ── काठमाडौं (Kathmandu Metro) ──────────────────────────

        RadioStation(
            id: "classic-fm",
            name: "क्लासिक एफएम",
            nameNepali: "Classic FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/9tng80z5pa0uv")!
        ),
        RadioStation(
            id: "radio-city",
            name: "रेडियो सिटी",
            nameNepali: "Radio City",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/fetv0masxiivv")!
        ),
        RadioStation(
            id: "capital-fm",
            name: "क्यापिटल एफएम",
            nameNepali: "Capital FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/k4g5ubp8z4zuv")!
        ),
        RadioStation(
            id: "wave-fm",
            name: "वेभ एफएम",
            nameNepali: "Wave FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/et3fspemcd0uv")!
        ),
        RadioStation(
            id: "hamro-radio",
            name: "हाम्रो रेडियो",
            nameNepali: "Hamro Radio",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/8kqr56puhrhvv")!
        ),
        RadioStation(
            id: "times-fm",
            name: "टाइम्स एफएम",
            nameNepali: "Times FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/3aorzyvpaymuv")!
        ),
        RadioStation(
            id: "abc-fm",
            name: "एबीसी एफएम",
            nameNepali: "ABC FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/v7sbng0epm0uv")!
        ),
        RadioStation(
            id: "radio-himalaya",
            name: "रेडियो हिमालय",
            nameNepali: "Radio Himalaya",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/07r4sm1uqg0uv")!
        ),
        RadioStation(
            id: "thaha-sanchar",
            name: "रेडियो थाहा सञ्चार",
            nameNepali: "Radio Thaha Sanchar",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/f1e3pza9ay8uv")!
        ),
        RadioStation(
            id: "humsafar",
            name: "रेडियो हमसफर",
            nameNepali: "Radio Humsafar",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/szfmr54krc9uv")!
        ),
        RadioStation(
            id: "nepali-online",
            name: "नेपाली अनलाइन रेडियो",
            nameNepali: "Nepali Online Radio",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/v2jtf324s2ktv")!
        ),
        RadioStation(
            id: "metro-radio",
            name: "मेट्रो रेडियो",
            nameNepali: "Metro Radio",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/k4120vwfny8uv")!
        ),

        // ── तराई / मधेश (Terai / Madhesh) ───────────────────────

        RadioStation(
            id: "madhesh-fm",
            name: "मधेश एफएम",
            nameNepali: "Madhesh FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/4sdd5pkyag8uv")!
        ),
        RadioStation(
            id: "birat",
            name: "रेडियो विराट",
            nameNepali: "Radio Birat",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/7fy610heb8zuv")!
        ),
        RadioStation(
            id: "birgunj-network",
            name: "वीरगञ्ज नेटवर्क",
            nameNepali: "Birgunj Network",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/atwjmdk3pyzvv")!
        ),
        RadioStation(
            id: "birgunj-eu",
            name: "वीरगञ्ज ईयू एफएम",
            nameNepali: "Birgunj EU FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/tdfnrjbmb8gtv")!
        ),
        RadioStation(
            id: "bara",
            name: "रेडियो बारा",
            nameNepali: "Radio Bara",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/cx7gme4t1nhvv")!
        ),
        RadioStation(
            id: "barahathawa",
            name: "बराहथवा एफएम",
            nameNepali: "Barahathawa FM 24hrs",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/as8n057z4k8uv")!
        ),
        RadioStation(
            id: "fulariya",
            name: "रेडियो फुलरिया",
            nameNepali: "Radio Fulariya",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/mvbhjec8w9pvv")!
        ),

        // ── अन्य (Other) ───────────────────────────────────────

        RadioStation(
            id: "tufan",
            name: "रेडियो तुफान",
            nameNepali: "Radio Tufan",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/e2a0wew9dd0uv")!
        ),
        RadioStation(
            id: "malashree",
            name: "मालश्री",
            nameNepali: "Malashree",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/fjdb83oq3e0uv")!
        ),
        RadioStation(
            id: "rastriya-sandesh",
            name: "राष्ट्रिय सन्देश",
            nameNepali: "Rastriya Sandesh",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/50ph1t14gwzuv")!
        ),
        RadioStation(
            id: "radio-audio",
            name: "रेडियो अडियो",
            nameNepali: "Radio Audio",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/8cshr82wx3duv")!
        ),
        RadioStation(
            id: "budhinanda",
            name: "रेडियो बुढीनन्दा एफएम",
            nameNepali: "Radio Budhinanda FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/xrxhqggpq7zuv")!
        ),
        RadioStation(
            id: "bishwas",
            name: "विश्वास एफएम",
            nameNepali: "Bishwas FM",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/2ga28kup6x8uv")!
        ),
        RadioStation(
            id: "radio-upt",
            name: "रेडियो उप्ट",
            nameNepali: "Radio Upt",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/8g5vbvllzz8tv")!
        ),
        RadioStation(
            id: "kachuli",
            name: "कचुली रेडियो",
            nameNepali: "Kachuli Radio",
            frequency: "Online",
            streamURL: URL(string: "https://stream.zeno.fm/2vr3h4dyafhvv")!
        ),
    ]

    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    private var itemObserver: NSKeyValueObservation?
    private var stallObserver: NSKeyValueObservation?
    private var loadingTimer: Timer?
    private var stallTimer: Timer?

    private init() {
        setupRemoteCommands()
    }

    // MARK: - Public

    /// Play a station. If the same station is already playing, stops it.
    func play(_ station: RadioStation) {
        if currentStation == station && playbackState == .playing {
            stop()
            return
        }

        stop()
        currentStation = station
        playbackState = .loading
        recordRecentStation(station.id)

        let asset = AVURLAsset(url: station.streamURL)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        player?.volume = volume

        // Observe player item status
        itemObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handleItemStatus(item.status)
            }
        }

        // Observe timeControlStatus to detect mid-stream stalls
        stallObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.handleTimeControlStatus(player.timeControlStatus)
            }
        }

        // Loading timeout — 15 seconds
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.playbackState == .loading else { return }
                self.playbackState = .error("Connection timed out")
                self.player?.pause()
                self.player = nil
            }
        }

        player?.play()
        updateNowPlaying(station)
    }

    /// Stop playback entirely.
    func stop() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        stallTimer?.invalidate()
        stallTimer = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        statusObserver?.invalidate()
        itemObserver?.invalidate()
        stallObserver?.invalidate()
        statusObserver = nil
        itemObserver = nil
        stallObserver = nil
        playbackState = .idle
        currentStation = nil
        clearNowPlaying()
    }

    /// Update volume.
    func setVolume(_ value: Float) {
        volume = value
        player?.volume = value
    }

    /// Whether the given station is the one currently playing.
    func isPlaying(_ station: RadioStation) -> Bool {
        currentStation == station && playbackState == .playing
    }

    /// Whether the given station is loading.
    func isLoading(_ station: RadioStation) -> Bool {
        currentStation == station && playbackState == .loading
    }

    /// Push a station to the front of the recent list (max 3, persisted).
    private func recordRecentStation(_ id: String) {
        var ids = recentStationIDs
        ids.removeAll { $0 == id }    // Remove duplicate
        ids.insert(id, at: 0)         // Push to front
        if ids.count > 3 { ids = Array(ids.prefix(3)) }
        recentStationIDs = ids
        UserDefaults.standard.set(ids, forKey: "recentRadioStations")
    }

    // MARK: - Private

    private func handleItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            loadingTimer?.invalidate()
            loadingTimer = nil
            playbackState = .playing
        case .failed:
            loadingTimer?.invalidate()
            loadingTimer = nil
            playbackState = .error("Stream unavailable")
        default:
            break
        }
    }

    /// Detects when a playing stream stalls (e.g. network drop).
    /// Gives it 10 seconds to recover before showing an error.
    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            // Stream recovered — cancel any pending stall timer
            stallTimer?.invalidate()
            stallTimer = nil
            if playbackState != .playing {
                playbackState = .playing
            }
        case .waitingToPlayAtSpecifiedRate:
            // Stalling — start a 10-second grace period
            guard stallTimer == nil, playbackState == .playing else { return }
            stallTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.playbackState == .playing else { return }
                    self.playbackState = .error("Stream lost — station may be offline")
                    self.player?.pause()
                }
            }
        case .paused:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Now Playing

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = false

        center.pauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        center.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
    }

    private func updateNowPlaying(_ station: RadioStation) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = station.name
        info[MPMediaItemPropertyArtist] = station.frequency
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
