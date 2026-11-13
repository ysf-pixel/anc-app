import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audio: AudioController
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                Spacer()
                VStack(spacing: 8) {
                    Text("LIVE LEVEL").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(String(format: "%.0f dB", audio.decibels))
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .foregroundStyle(color(for: audio.level))
                    Text(audio.level.rawValue).font(.title3.weight(.semibold))
                }
                .accessibilityElement(children: .combine)

                MeterBar(value: audio.decibels)
                Text(audio.routeMessage).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text(audio.permissionMessage).font(.footnote).multilineTextAlignment(.center)
                    .padding(.horizontal)
                if audio.operatingMode == .jailbreakCompanion {
                    Text(audio.companionMessage).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Button(audio.isRunning ? "Stop Meter" : "Start Meter") {
                    if audio.isRunning { audio.stop() } else { Task { await audio.requestAndStart() } }
                }
                .buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                Spacer()
                Text(audio.operatingMode == .normal
                     ? "Normal mode: level meter only — not active noise cancellation"
                     : "Jailbreak mode requires a rootless companion — not active noise cancellation")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("ANC")
            .toolbar { Button { showingSettings = true } label: { Image(systemName: "gearshape") } }
            .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(audio) }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func color(for level: SoundLevel) -> Color {
        switch level { case .green: .green; case .yellow: .yellow; case .red: .red }
    }
}

private struct MeterBar: View {
    let value: Double
    var normalized: Double { min(max((value + 80) / 80, 0), 1) }
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule().fill(LinearGradient(colors: [.green, .yellow, .red], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * normalized)
            }
        }.frame(height: 14).padding(.horizontal)
    }
}
