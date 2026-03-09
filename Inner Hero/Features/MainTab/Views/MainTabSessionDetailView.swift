import SwiftUI

struct MainTabSessionDetailView: View {
    let session: ExposureSessionResult
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Exposure")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(session.exposure?.title ?? "Untitled")
                        .font(.title2.weight(.semibold))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "calendar", title: "Start", value: session.startAt.formatted(date: .long, time: .shortened))
                    
                    if let endAt = session.endAt {
                        DetailRow(icon: "checkmark.circle", title: "End", value: endAt.formatted(date: .long, time: .shortened))
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Anxiety levels")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Before session")
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
                                Text("After session")
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
                        Text("Notes")
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
        .navigationTitle("Session details")
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
