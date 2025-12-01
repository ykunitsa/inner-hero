import SwiftUI
import SwiftData

struct ExposureDetailView: View {
    let exposure: Exposure
    let onStartSession: () -> Void
    
    private var totalSteps: Int { exposure.steps.count }
    private var stepsWithTimer: Int { exposure.steps.filter { $0.hasTimer }.count }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                heroHeaderSection
                quickStatsSection
                descriptionCard
                if !exposure.steps.isEmpty {
                    stepsSection
                }
                sessionsHistoryCard
                startSessionButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: EditExposureView(exposure: exposure)) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.teal)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }
    
    private var heroHeaderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 50))
                    .foregroundStyle(.teal)
            }
            Text(exposure.title)
                .font(.title.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(icon: "list.number", value: "\(totalSteps)", label: "Шагов", color: .teal)
            QuickStatCard(icon: "timer", value: "\(stepsWithTimer)", label: "С таймером", color: .orange)
            QuickStatCard(icon: "chart.bar.fill", value: "\(exposure.sessionResults.count)", label: "Сеансов", color: .teal)
        }
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.body)
                    .foregroundStyle(.teal)
                Text("Описание")
                    .font(.body.weight(.semibold))
            }
            
            Text(exposure.exposureDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
                    .font(.body)
                    .foregroundStyle(.teal)
                Text("Шаги выполнения")
                    .font(.body.weight(.semibold))
            }
            
            VStack(spacing: 12) {
                ForEach(Array(exposure.steps.enumerated()), id: \.offset) { index, step in
                    StepDetailCard(step: step, index: index)
                }
            }
        }
    }
    
    private var sessionsHistoryCard: some View {
        NavigationLink(destination: SessionHistoryView(exposure: exposure)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(.teal)
                    Text("История сеансов")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if exposure.sessionResults.count > 0 {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Всего")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(exposure.sessionResults.count)")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Последний")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let lastSession = exposure.sessionResults.sorted(by: { $0.startAt > $1.startAt }).first {
                                Text(lastSession.startAt, style: .relative)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.teal)
                            }
                        }
                    }
                } else {
                    Text("Нет завершенных сеансов")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var startSessionButton: some View {
        Button(action: onStartSession) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Начать сеанс")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.teal)
                    .shadow(color: Color.teal.opacity(0.3), radius: 12, y: 6)
            )
        }
        .accessibilityLabel("Начать сеанс")
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct StepDetailCard: View {
    let step: Step
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.teal)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(step.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if step.hasTimer {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("\(step.timerDuration / 60):\(String(format: "%02d", step.timerDuration % 60))")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.orange))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Шаг \(index + 1): \(step.text)")
    }
}
