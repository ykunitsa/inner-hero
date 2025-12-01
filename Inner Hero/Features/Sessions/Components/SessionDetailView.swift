import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: SessionResult
    
    private enum Layout {
        static let screenHorizontalPadding: CGFloat = 20
        static let screenVerticalPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 32
        static let contentSpacing: CGFloat = 12
        static let tightSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 20
        static let cardCornerRadius: CGFloat = 16
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: session.startAt)
    }
    
    private var duration: String {
        guard let endAt = session.endAt else { return "Не завершён" }
        let interval = endAt.timeIntervalSince(session.startAt)
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var anxietyChange: Int? {
        guard let anxietyAfter = session.anxietyAfter else { return nil }
        return session.anxietyBefore - anxietyAfter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                VStack(alignment: .leading, spacing: Layout.tightSpacing) {
                    Text("Дата сеанса")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                    Label(formattedDate, systemImage: "calendar")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Дата сеанса: \(formattedDate)")
                
                if let anxietyAfter = session.anxietyAfter {
                    AnxietyProgressChart(
                        anxietyBefore: session.anxietyBefore,
                        anxietyAfter: anxietyAfter
                    )
                }
                
                VStack(spacing: Layout.contentSpacing) {
                    HStack(spacing: Layout.contentSpacing) {
                        StatCard(
                            title: "Тревога до",
                            value: "\(session.anxietyBefore)",
                            color: .blue
                        )
                        
                        if let anxietyAfter = session.anxietyAfter {
                            StatCard(
                                title: "Тревога после",
                                value: "\(anxietyAfter)",
                                color: anxietyAfter < session.anxietyBefore ? .green : .red
                            )
                            
                            if let change = anxietyChange {
                                StatCard(
                                    title: "Изменение",
                                    value: "\(change > 0 ? "-" : "+")\(abs(change))",
                                    color: change > 0 ? .green : (change < 0 ? .red : .gray)
                                )
                            }
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: Layout.tightSpacing) {
                            Text("Длительность")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(duration)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        }
                        
                        Spacer()
                        
                        if session.endAt != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                                .accessibilityLabel("Завершён")
                        } else {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundStyle(.gray)
                                .accessibilityLabel("В процессе")
                        }
                    }
                    .padding(Layout.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                            .fill(.background.tertiary)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Длительность: \(duration), " + 
                        (session.endAt != nil ? "Завершён" : "В процессе"))
                }
                
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        Text("Заметки")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text(session.notes)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(Layout.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                                    .fill(.background.tertiary)
                            )
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Заметки: \(session.notes)")
                }
                
                if let exposure = session.exposure {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        Text("Экспозиция")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: Layout.tightSpacing) {
                            Text(exposure.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text(exposure.exposureDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Layout.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                                .fill(.background.tertiary)
                        )
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Экспозиция: \(exposure.title). \(exposure.exposureDescription)")
                }
            }
            .padding(.horizontal, Layout.screenHorizontalPadding)
            .padding(.vertical, Layout.screenVerticalPadding)
        }
        .background(.background.secondary)
        .ignoresSafeArea(.all)
        .navigationTitle("Детали сеанса")
        .navigationBarTitleDisplayMode(.inline)
    }
}
