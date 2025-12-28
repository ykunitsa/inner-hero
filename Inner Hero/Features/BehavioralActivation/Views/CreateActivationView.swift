import SwiftUI
import SwiftData

struct CreateActivationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var activities: [String] = [""]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        activities.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    titleSection
                    activitiesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.92, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("New Activation List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TextColors.toolbar)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveActivation()
                    }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? AppTheme.primaryColor : TextColors.tertiary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pencil")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Title")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
            }
            
            TextField("e.g., Morning Routine", text: $title)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                )
        }
    }
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Activities")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                
                Spacer()
                
                Button {
                    withAnimation {
                        activities.append("")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            VStack(spacing: 12) {
                ForEach(activities.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text("\(index + 1).")
                            .font(.body.weight(.medium))
                            .foregroundStyle(TextColors.secondary)
                            .frame(width: 24)
                        
                        TextField("Activity name", text: $activities[index])
                            .textFieldStyle(.plain)
                            .font(.body)
                        
                        if activities.count > 1 {
                            Button {
                                withAnimation {
                                    _ = activities.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
    }
    
    private func saveActivation() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let validActivities = activities
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !trimmedTitle.isEmpty, !validActivities.isEmpty else {
            errorMessage = "Please enter a title and at least one activity"
            showingError = true
            return
        }
        
        let activation = ActivityList(
            title: trimmedTitle,
            activities: validActivities,
            isPredefined: false
        )
        
        modelContext.insert(activation)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    CreateActivationView()
        .modelContainer(for: ActivityList.self, inMemory: true)
}

