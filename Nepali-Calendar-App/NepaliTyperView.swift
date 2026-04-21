//
//  NepaliTyperView.swift
//  Nepali-Calendar-App
//
//  Romanized → Nepali typing panel. User types Roman on the keyboard
//  and sees only Devanagari in the editor — no Roman is ever shown.
//

import SwiftUI
import Aptabase

struct NepaliTyperView: View {
    private enum Pane: String, CaseIterable { case write, saved }

    @State private var pane: Pane = .write
    @State private var showCopied: Bool = false
    @State private var showSaved: Bool = false

    @FocusState private var focused: Bool

    private let store = NepaliNotesStore.shared
    private let engine = NepaliTyperEngine.shared
    private let state = NepaliTyperState.shared

    private var romanBuffer: String {
        get { state.romanBuffer }
        nonmutating set { state.romanBuffer = newValue }
    }

    /// Devanagari representation of the current Roman buffer.
    private var display: String {
        engine.transliterateText(romanBuffer)
    }

    /// Binding that lets TextEditor read Devanagari and write edits,
    /// mapping changes back onto the underlying Roman buffer.
    private var textBinding: Binding<String> {
        Binding(
            get: { display },
            set: { newValue in applyEditorChange(newValue) }
        )
    }

    /// When true, hides the "open in full editor" button (e.g. inside the
    /// full-editor window itself).
    var showsFullEditorButton: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            tabBar

            switch pane {
            case .write: writePane
            case .saved: savedPane
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.write, label: "Write", icon: "pencil.line")
            tabButton(.saved, label: "Saved\(store.notes.isEmpty ? "" : " (\(store.notes.count))")", icon: "tray.full")
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08))
        )
    }

    private func tabButton(_ target: Pane, label: String, icon: String) -> some View {
        let selected = pane == target
        return Button {
            if pane != target {
                pane = target
                Aptabase.shared.trackEvent("typer_tab_switched", with: ["tab": target.rawValue])
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selected ? Color(nsColor: .windowBackgroundColor) : Color.clear)
                    .shadow(color: selected ? Color.black.opacity(0.08) : .clear, radius: 1, y: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Write Pane

    private var writePane: some View {
        editorCard
    }

    private var shortcutsHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
            Text("Type ' to add halant (्) between consonants.")
                .font(.system(size: 10))
        }
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
        .truncationMode(.tail)
        .padding(.horizontal, 10)
        .padding(.top, 1)
        .padding(.bottom, 4)
    }

    private var editorCard: some View {
        VStack(spacing: 0) {
            TextEditor(text: textBinding)
                .focused($focused)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    if romanBuffer.isEmpty {
                        Text("यहाँ नेपालीमा लेख्नुहोस्…")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .allowsHitTesting(false)
                    }
                }

            Divider()
                .opacity(0.5)

            HStack(spacing: 6) {
                Spacer()

                if hasContent {
                    labeledButton(
                        icon: "xmark",
                        title: "Clear",
                        activeColor: nil,
                        active: false
                    ) {
                        romanBuffer = ""
                        focused = true
                        Aptabase.shared.trackEvent("typer_cleared")
                    }
                    .help("Clear")

                    labeledButton(
                        icon: showSaved ? "checkmark" : "tray.and.arrow.down",
                        title: showSaved ? "Saved" : "Save",
                        activeColor: .green,
                        active: showSaved
                    ) {
                        guard store.add(display) else { return }
                        romanBuffer = ""
                        flashSaved()
                        Aptabase.shared.trackEvent("typer_saved")
                    }
                    .help("Save note")

                    copyButton
                }

                if showsFullEditorButton {
                    fullEditorButton
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 2)

            shortcutsHint
        }
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.22), lineWidth: 0.5)
        )
    }

    // MARK: - Saved Pane

    @ViewBuilder
    private var savedPane: some View {
        if store.notes.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("No saved notes yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Write something and tap the save icon.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(store.notes) { note in
                        noteRow(note)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func noteRow(_ note: NepaliNote) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(note.text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(note.text, forType: .string)
                Aptabase.shared.trackEvent("note_copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Copy")

            Button {
                store.delete(note.id)
                Aptabase.shared.trackEvent("note_deleted")
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Editor Change Mapping

    /// Maps a TextEditor change on the Devanagari display back onto the
    /// underlying Roman buffer, so the engine's stateful transliteration
    /// stays correct (e.g. "na" → "न", not "न" + "अ").
    private func applyEditorChange(_ newValue: String) {
        let displayOld = display
        if newValue == displayOld { return }

        // Pure append from the end: user typed one or more characters.
        if newValue.count > displayOld.count, newValue.hasPrefix(displayOld) {
            let appended = String(newValue.dropFirst(displayOld.count))
            romanBuffer += appended
            return
        }

        // Pure deletion from the end: user pressed backspace.
        if newValue.count < displayOld.count, displayOld.hasPrefix(newValue) {
            // Pop Roman characters until the transliteration matches.
            while !romanBuffer.isEmpty {
                romanBuffer.removeLast()
                if engine.transliterateText(romanBuffer) == newValue { return }
            }
            // Couldn't reconstruct — accept the new value as raw Roman input.
            romanBuffer = newValue
            return
        }

        // Bulk change (paste, mid-edit, cursor replace): treat as raw input.
        romanBuffer = newValue
    }

    /// True when the user has typed something non-whitespace.
    private var hasContent: Bool {
        !display.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Copy Button

    private var copyButton: some View {
        labeledButton(
            icon: showCopied ? "checkmark" : "doc.on.doc",
            title: showCopied ? "Copied" : "Copy",
            activeColor: .green,
            active: showCopied
        ) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(display, forType: .string)
            flashCopied()
            Aptabase.shared.trackEvent("typer_copied")
        }
        .help("Copy Nepali text")
    }

    // MARK: - Full Editor Button

    private var fullEditorButton: some View {
        labeledButton(
            icon: "square.and.pencil",
            title: "Editor",
            activeColor: nil,
            active: false
        ) {
            NepaliEditorWindow.show()
            Aptabase.shared.trackEvent("typer_full_editor_opened")
        }
        .help("Open in full editor window")
    }

    // MARK: - Labeled Button

    @ViewBuilder
    private func labeledButton(
        icon: String,
        title: String,
        activeColor: Color?,
        active: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(active ? (activeColor ?? Color.secondary) : Color.secondary)
            .padding(.horizontal, 6)
            .frame(height: 18)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.22), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flash helpers

    private func flashCopied() {
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showCopied = false }
        }
    }

    private func flashSaved() {
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSaved = false }
        }
    }
}

#Preview {
    NepaliTyperView()
        .frame(width: 380, height: 260)
}
