import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var audio: AudioController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Mode") {
                    Picker("Audio mode", selection: $audio.operatingMode) {
                        ForEach(OperatingMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: audio.operatingMode) { mode in audio.setOperatingMode(mode) }
                    Text(audio.operatingMode.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if audio.operatingMode == .jailbreakCompanion {
                        Text(audio.companionMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Input") {
                    Picker("Microphone", selection: $audio.selectedInputID) {
                        Text("System default").tag(String?.none)
                        ForEach(audio.inputs) { input in Text("\(input.name) (\(input.type))").tag(Optional(input.id)) }
                    }.onChange(of: audio.selectedInputID) { value in audio.selectInput(value) }
                }
                Section("Output") {
                    Toggle("Prefer iPhone speaker", isOn: $audio.useSpeaker).onChange(of: audio.useSpeaker) { value in audio.setSpeaker(value) }
                    Text("Bluetooth and wired output routes are selected by iOS. This switch only requests speaker vs. the system default.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Experimental") {
                    Slider(value: $audio.processorStrength, in: 0...1) { Text("Analysis strength") }
                    Text("This changes a displayed analysis value only. It never plays anti-noise or routes microphone audio to the speaker.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Safety & limitations") {
                    Text("The meter is an estimated digital level (dBFS), not a calibrated sound-pressure (dB SPL) measurement.")
                    Text("Standard iOS apps cannot provide true physical or system-wide active noise cancellation.")
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
