import SwiftUI

struct MainTabSessionDetailView: View {
    let session: ExposureSessionResult
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Экспозиция")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(session.exposure?.title ?? "Без названия")
                        .font(.title2.weight(.semibold))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "calendar", title: "Начало", value: session.startAt.formatted(date: .long, time: .shortened))
                    
                    if let endAt = session.endAt {
                        DetailRow(icon: "checkmark.circle", title: "Окончание", value: endAt.formatted(date: .long, time: .shortened))
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Уровни тревоги")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("До сеанса")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(session.anxietyBefore)/10")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(anxietyColorForLevel(session.anxietyBefore))
                        }
                        
                        Spacer()
                        
                        if let anxietyAfter = session.anxietyAfter {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("После сеанса")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(anxietyAfter)/10")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(anxietyColorForLevel(anxietyAfter))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
                
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Заметки")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(session.notes)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Детали сеанса")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func anxietyColorForLevel(_ level: Int) -> Color {
        switch level {
        case 0...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}
