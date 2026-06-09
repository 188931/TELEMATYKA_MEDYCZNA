import SwiftUI

struct BPSimulationStep: Decodable {
    let step: String
    let displayValue: Int
    let message: String
    let resultSys: Int?
    let resultDia: Int?
    let resultHr:  Int?
    let delayMs:   Int

    enum CodingKeys: String, CodingKey {
        case step
        case displayValue = "display_value"
        case message
        case resultSys    = "result_sys"
        case resultDia    = "result_dia"
        case resultHr     = "result_hr"
        case delayMs      = "delay_ms"
    }
}

struct BPSimulationResponse: Decodable {
    let steps: [BPSimulationStep]
}


enum BPEmulatorPhase {
    case idle
    case running(message: String, displayValue: Int, maxValue: Int)
    case done(sys: Int, dia: Int, hr: Int)
    case error(String)
}

struct BPEmulatorSheet: View {

    let onResult: (Int, Int, Int) -> Void
    let onCancel: () -> Void

    @State private var phase: BPEmulatorPhase = .idle
    @State private var isRunning = false
    @State private var animatedAngle: Double = -135
    @State private var pulseScale: CGFloat = 1.0
    @State private var currentMessage = "Naciśnij START, aby rozpocząć pomiar"
    @State private var displayValue = 0
    @State private var maxValue = 200

    @State private var resultSys: Int? = nil
    @State private var resultDia: Int? = nil
    @State private var resultHr:  Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                ZStack {
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.3), .green.opacity(0.4), .yellow.opacity(0.4), .red.opacity(0.4)]),
                                center: .center,
                                startAngle: .degrees(-135),
                                endAngle: .degrees(135)
                            ),
                            lineWidth: 12
                        )
                        .frame(width: 200, height: 200)

                    ForEach(0..<28) { i in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: i % 7 == 0 ? 2 : 1, height: i % 7 == 0 ? 14 : 8)
                            .offset(y: -82)
                            .rotationEffect(.degrees(-135 + Double(i) * (270.0 / 27.0)))
                    }

                    Capsule()
                        .fill(isRunning ? Color.red : Color.secondary)
                        .frame(width: 3, height: 70)
                        .offset(y: -35)
                        .rotationEffect(.degrees(animatedAngle))
                        .animation(.easeOut(duration: 0.15), value: animatedAngle)

                    VStack(spacing: 4) {
                        Text("\(displayValue)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(colorForPhase)
                            .scaleEffect(pulseScale)
                            .animation(.spring(response: 0.3), value: pulseScale)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.1), value: displayValue)
                        Text("mmHg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                Text(currentMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 40)
                    .padding(.horizontal)
                    .id(currentMessage)          
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: currentMessage)

                if let sys = resultSys, let dia = resultDia, let hr = resultHr {
                    HStack(spacing: 16) {
                        ResultBadge(label: "Skurczowe", value: "\(sys)", unit: "mmHg", color: .red)
                        ResultBadge(label: "Rozkurczowe", value: "\(dia)", unit: "mmHg", color: .blue)
                        ResultBadge(label: "Tętno", value: "\(hr)", unit: "bpm", color: .green)
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: resultSys != nil)
                }

                Spacer()

                VStack(spacing: 12) {
                    if resultSys != nil {
                        Button {
                            onResult(resultSys!, resultDia!, resultHr!)
                        } label: {
                            Label("Wstaw wynik do formularza", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)

                        Button("Zmierz ponownie") {
                            resetAndStart()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    } else if !isRunning {
                        Button {
                            resetAndStart()
                        } label: {
                            Label("START – Rozpocznij pomiar", systemImage: "waveform.path.ecg")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Trwa pomiar…")
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Emulator ciśnieniomierza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { onCancel() }
                        .disabled(isRunning)
                }
            }
        }
    }

    private var colorForPhase: Color {
        if resultSys != nil { return .green }
        if isRunning { return .red }
        return .primary
    }

    private func angle(for value: Int) -> Double {
        let clamped = min(max(Double(value), 0), 300)
        return -135 + (clamped / 300.0) * 270
    }

    private func resetAndStart() {
        resultSys = nil; resultDia = nil; resultHr = nil
        displayValue = 0; animatedAngle = -135
        currentMessage = "Łączę z urządzeniem…"
        Task { await runSimulation() }
    }

    private func runSimulation() async {
        isRunning = true
        defer { isRunning = false }

        do {
            let steps = try await fetchSimulationSteps()
            for step in steps {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        displayValue = step.displayValue
                    }
                    animatedAngle = angle(for: step.displayValue)
                    currentMessage = step.message

                    if step.message.contains("Wykryto") {
                        pulseScale = 1.15
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            pulseScale = 1.0
                        }
                    }
                }

                if step.step == "done", let sys = step.resultSys, let dia = step.resultDia, let hr = step.resultHr {
                    await MainActor.run {
                        resultSys = sys; resultDia = dia; resultHr = hr
                        displayValue = sys
                        animatedAngle = angle(for: sys)
                    }
                    return
                }

                if step.delayMs > 0 {
                    try await Task.sleep(nanoseconds: UInt64(step.delayMs) * 1_000_000)
                }
            }
        } catch {
            await MainActor.run {
                currentMessage = "Błąd pomiaru: \(error.localizedDescription)"
            }
        }
    }

    private func fetchSimulationSteps() async throws -> [BPSimulationStep] {
        let url = URL(string: "http://127.0.0.1:8000/simulate-bp/")!
        var request = URLRequest(url: url, timeoutInterval: 3)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let response = try? JSONDecoder().decode(BPSimulationResponse.self, from: data) {
            return response.steps
        }

        return BPSimulationStepGenerator.generate()
    }
}

enum BPSimulationStepGenerator {
    static func generate() -> [BPSimulationStep] {
        let targetSys = Int.random(in: 110...155)
        let targetDia = Int.random(in: 70...95)
        let targetHr  = Int.random(in: 60...90)
        let maxInflate = targetSys + Int.random(in: 20...35)

        var steps: [BPSimulationStep] = []

        var v = 0
        while v <= maxInflate {
            steps.append(.init(step: "inflating", displayValue: v, message: "Pompowanie... \(v) mmHg",
                               resultSys: nil, resultDia: nil, resultHr: nil, delayMs: 120))
            v += 10
        }
        var current = maxInflate
        var sysDetected = false; var diaDetected = false
        while current > 30 {
            var msg = "Pomiar... \(current) mmHg"
            if !sysDetected && current <= targetSys { sysDetected = true; msg = "Wykryto skurczowe: \(targetSys) mmHg" }
            if !diaDetected && current <= targetDia { diaDetected = true; msg = "Wykryto rozkurczowe: \(targetDia) mmHg" }
            steps.append(.init(step: "deflating", displayValue: current, message: msg,
                               resultSys: nil, resultDia: nil, resultHr: nil, delayMs: 80))
            current -= 2
        }
        steps.append(.init(step: "done", displayValue: targetSys,
                           message: "Wynik: \(targetSys)/\(targetDia) mmHg, tętno \(targetHr) bpm",
                           resultSys: targetSys, resultDia: targetDia, resultHr: targetHr, delayMs: 0))
        return steps
    }
}

private struct ResultBadge: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}