//
//  RadioView.swift
//  Nepali-Calendar-App
//
//  Radio tab: stream popular Nepali FM stations live.
//  Simple list with play/pause, volume, and animated indicators.
//

import SwiftUI
import Aptabase

// Matches the crimson used throughout the app
private let radioCrimson = Color(red: 0.91, green: 0.20, blue: 0.29)

// MARK: - Radio Tab View

struct RadioView: View {

    private let radio = RadioPlayerService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "radio")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Nepali FM Radio")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if radio.playbackState == .playing {
                    EqualizerBars()
                    Button {
                        radio.stop()
                        Aptabase.shared.trackEvent("radio_stopped")
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            // Station list (scrollable)
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    // Recently played (dynamic, max 3)
                    if !radio.recentStations.isEmpty {
                        HStack {
                            Text("पछिल्लो बजाइएको")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        ForEach(radio.recentStations) { station in
                            StationRow(station: station, radio: radio)
                            Divider().padding(.leading, 52)
                        }

                        HStack {
                            Text("सबै स्टेशनहरू")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }

                    // All stations (exclude recents to avoid duplication)
                    let recentIDs = Set(radio.recentStationIDs)
                    let remainingStations = radio.stations.filter { !recentIDs.contains($0.id) }
                    ForEach(remainingStations) { station in
                        StationRow(station: station, radio: radio)
                        if station.id != remainingStations.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .frame(height: 420)

            Divider()

            // Volume control
            if radio.currentStation != nil {
                volumeControl
                Divider()
            }

            // Error message
            if case .error(let msg) = radio.playbackState {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Footer
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                Text("Powered by Zeno.fm · Live from Nepal")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.vertical, 8)
        }
        .onDisappear {
            // Don't stop on tab switch — let audio continue
        }
    }

    // MARK: - Volume

    private var volumeControl: some View {
        HStack(spacing: 8) {
            Image(systemName: radio.volume == 0 ? "speaker.slash.fill" : "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Slider(
                value: Binding(
                    get: { Double(radio.volume) },
                    set: { radio.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .controlSize(.small)
            .tint(radioCrimson)

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Station Row

private struct StationRow: View {
    let station: RadioStation
    let radio: RadioPlayerService
    @State private var isHovered = false

    private var isPlaying: Bool { radio.isPlaying(station) }
    private var isLoading: Bool { radio.isLoading(station) }
    private var isActive: Bool { radio.currentStation == station }

    var body: some View {
        Button {
            if isPlaying {
                radio.stop()
            } else {
                radio.play(station)
            }
            Aptabase.shared.trackEvent("radio_station_tapped", with: [
                "station": station.id,
                "action": isPlaying ? "stop" : "play"
            ])
        } label: {
            HStack(spacing: 12) {
                // Play/pause icon
                ZStack {
                    Circle()
                        .fill(isActive ? radioCrimson : Color.primary.opacity(0.08))
                        .frame(width: 32, height: 32)

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isActive ? .white : .secondary)
                            .offset(x: isPlaying ? 0 : 1) // Optical alignment
                    }
                }

                // Station info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(station.nameNepali) | \(station.name)")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(station.frequency)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Live indicator
                if isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel("\(station.name), \(station.frequency)")
        .accessibilityHint(isPlaying ? "Currently playing. Tap to stop." : "Tap to play.")
    }
}

// MARK: - Equalizer Bars Animation

private struct EqualizerBars: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(radioCrimson)
                    .frame(width: 3, height: animating ? barHeight(for: index) : 4)
                    .animation(
                        .easeInOut(duration: duration(for: index))
                        .repeatForever(autoreverses: true),
                        value: animating
                    )
            }
        }
        .frame(height: 14)
        .onAppear { animating = true }
    }

    private func barHeight(for index: Int) -> CGFloat {
        switch index {
        case 0: return 12
        case 1: return 8
        case 2: return 14
        default: return 10
        }
    }

    private func duration(for index: Int) -> Double {
        switch index {
        case 0: return 0.4
        case 1: return 0.55
        case 2: return 0.35
        default: return 0.45
        }
    }
}

// MARK: - Persistent Mini Player (above tab bar)

struct RadioMiniPlayer: View {
    private let radio = RadioPlayerService.shared

    private var isPlaying: Bool { radio.playbackState == .playing }
    private var isLoading: Bool { radio.playbackState == .loading }

    var body: some View {
        if radio.currentStation != nil {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 10) {
                    // Station name
                    if let station = radio.currentStation {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(station.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if isPlaying {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 4, height: 4)
                                    Text("LIVE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.green)
                                }
                            } else if isLoading {
                                Text("Buffering…")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Volume slider (compact)
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.quaternary)
                        Slider(
                            value: Binding(
                                get: { Double(radio.volume) },
                                set: { radio.setVolume(Float($0)) }
                            ),
                            in: 0...1
                        )
                        .controlSize(.mini)
                        .tint(radioCrimson)
                        .frame(width: 60)
                    }

                    // Stop
                    Button {
                        radio.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(radioCrimson)
                            .frame(width: 26, height: 26)
                            .background(radioCrimson.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))
            }
        }
    }
}

#Preview {
    RadioView()
        .frame(width: 380)
}
