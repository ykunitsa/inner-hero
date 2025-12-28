import SwiftUI
import SwiftData
import Combine

struct ActivationDetailView: View {
    let activation: ActivityList
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                heroHeaderSection
                quickStatsSection
                activitiesSection
                startActivityButton
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
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !activation.isPredefined {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditActivationView(activation: activation)
        }
    }
    
    private var heroHeaderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.walk")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(activation.title)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                
                if activation.isPredefined {
                    Text("Built-in Activation List")
                        .font(.subheadline)
                        .foregroundStyle(TextColors.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(
                icon: "list.bullet",
                value: "\(activation.activities.count)",
                label: "Activities",
                color: .green
            )
            
            QuickStatCard(
                icon: activation.isPredefined ? "lock.fill" : "person.fill",
                value: activation.isPredefined ? "Built-in" : "Custom",
                label: "Type",
                color: .mint
            )
        }
    }
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
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
            }
            
            if activation.activities.isEmpty {
                Text("No activities yet")
                    .font(.body)
                    .foregroundStyle(TextColors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(activation.activities.enumerated()), id: \.offset) { index, activity in
                        ActivityRowCard(activity: activity, index: index)
                    }
                }
            }
        }
    }
    
    private var startActivityButton: some View {
        NavigationLink(destination: StartActivationView(activation: activation)) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Start Session")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(activation.activities.isEmpty)
        .opacity(activation.activities.isEmpty ? 0.5 : 1.0)
        .accessibilityLabel("Start activation session")
    }
}

// MARK: - Supporting Views

struct ActivityRowCard: View {
    let activity: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.green)
            }
            
            Text(activity)
                .font(.body)
                .foregroundStyle(TextColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.99, blue: 1.0),
                            Color(red: 0.96, green: 0.97, blue: 0.99)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Activity \(index + 1): \(activity)")
    }
}

// MARK: - Start Activation View

struct StartActivationView: View {
    let activation: ActivityList
    
    @State private var showingActivityList = false
    @State private var selectedActivity: String?
    @State private var navigateToSession = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.92, green: 0.95, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(activation.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose how to select your activity")
                            .font(.subheadline)
                            .foregroundStyle(TextColors.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Select from list button
                    Button {
                        showingActivityList = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "list.bullet")
                                .font(.body.weight(.semibold))
                            Text("Select Activity from List")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Pick random button
                    Button {
                        if let randomActivity = activation.activities.randomElement() {
                            selectedActivity = randomActivity
                            navigateToSession = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "shuffle")
                                .font(.body.weight(.semibold))
                            Text("Pick Random Activity")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationTitle("Start Session")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingActivityList) {
            ActivitySelectionSheet(
                activities: activation.activities,
                onSelect: { activity in
                    selectedActivity = activity
                    showingActivityList = false
                    navigateToSession = true
                }
            )
        }
        .navigationDestination(isPresented: $navigateToSession) {
            if let activity = selectedActivity {
                ActivationSessionView(
                    activation: activation,
                    selectedActivity: activity
                )
            }
        }
    }
}

// MARK: - Activity Selection Sheet

struct ActivitySelectionSheet: View {
    let activities: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                        Button {
                            #if canImport(UIKit)
                            HapticFeedback.selection()
                            #endif
                            onSelect(activity)
                        } label: {
                            HStack(alignment: .center, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Text("\(index + 1)")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
                                
                                Text(activity)
                                    .font(.body)
                                    .foregroundStyle(TextColors.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(TextColors.tertiary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
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
            .navigationTitle("Select Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Activation Session View

struct ActivationSessionView: View {
    let activation: ActivityList
    let selectedActivity: String
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionStartTime = Date()
    @State private var showingCompletionView = false
    @State private var isCompleted = false
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sessionStartTime)
    }
    
    private var elapsedTime: String {
        let elapsed = currentTime.timeIntervalSince(sessionStartTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.mint.opacity(0.1),
                    Color.green.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            Image(systemName: "figure.walk")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Your Activity")
                                .font(.subheadline)
                                .foregroundStyle(TextColors.tertiary)
                            
                            Text(selectedActivity)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Time info card
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Started")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(TextColors.tertiary)
                            Text(formattedStartTime)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(TextColors.primary)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 32)
                        
                        VStack(spacing: 4) {
                            Text("Duration")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(TextColors.tertiary)
                            Text(elapsedTime)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.green)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Instructions card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text("Instructions")
                                .font(.headline)
                                .foregroundStyle(TextColors.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(
                                number: 1,
                                text: "Take your time to complete this activity"
                            )
                            InstructionRow(
                                number: 2,
                                text: "Focus on being present in the moment"
                            )
                            InstructionRow(
                                number: 3,
                                text: "Notice how you feel during and after"
                            )
                            InstructionRow(
                                number: 4,
                                text: "Rate your pleasure when finished"
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Complete button
                    if !isCompleted {
                        Button {
                            showingCompletionView = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                Text("Mark as Complete")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(activation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            sessionStartTime = Date()
            currentTime = Date()
        }
        .sheet(isPresented: $showingCompletionView) {
            ActivationCompletionView(
                activityName: selectedActivity,
                startedAt: sessionStartTime,
                onComplete: { rating in
                    completeSession(rating: rating)
                }
            )
        }
    }
    
    private func completeSession(rating: Int?) {
        let session = BehavioralActivationSession(
            startedAt: sessionStartTime,
            completedAt: Date(),
            selectedActivity: selectedActivity,
            pleasureRating: rating
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            #if canImport(UIKit)
            HapticFeedback.success()
            #endif
            isCompleted = true
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } catch {
            print("Failed to save session: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            
            Text(text)
                .font(.body)
                .foregroundStyle(TextColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        ActivationDetailView(
            activation: ActivityList(
                title: "Morning Routine",
                activities: ["Exercise for 30 minutes", "Meditate", "Healthy breakfast", "Read for 15 minutes"],
                isPredefined: false
            )
        )
    }
    .modelContainer(for: ActivityList.self, inMemory: true)
}

