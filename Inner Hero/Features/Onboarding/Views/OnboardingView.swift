import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: Spacing.xxxl)
                
                // App Icon/Title Section
                VStack(spacing: Spacing.md) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    Text("Inner Hero")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(TextColors.primary)
                }
                .padding(.bottom, Spacing.xl)
                
                // Main Content Section
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Brief Explanation
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Welcome")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(TextColors.primary)
                        
                        Text("Inner Hero helps you practice exposure therapy for anxiety. Create scenarios, run sessions, and track your progress.")
                            .font(.body)
                            .foregroundStyle(TextColors.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Warning Section
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Warning Header
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.body)
                                .foregroundStyle(AppTheme.State.warning)
                                .accessibilityHidden(true)
                            
                            Text("Important notice")
                                .font(.headline)
                                .foregroundStyle(TextColors.primary)
                        }
                        .accessibilityElement(children: .combine)
                        
                        // Warning Content
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("This app **does not replace** professional psychotherapy or medical care.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("If you experience serious symptoms of anxiety or other mental health conditions, please contact a qualified professional.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Use this app as an additional tool as part of a comprehensive approach to your mental health care.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(TextColors.secondary)
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .fill(AppTheme.State.warning.opacity(Opacity.softBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .stroke(AppTheme.State.warning.opacity(Opacity.standardBorder), lineWidth: 1)
                    )
                }
                .padding(.horizontal, Spacing.md)
                
                Spacer()
                    .frame(minHeight: Spacing.xl)
                
                // Continue Button
                Button {
                    #if os(iOS)
                    HapticFeedback.light()
                    #endif
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: TouchTarget.minimum)
                        .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .accessibilityLabel("Continue")
                .accessibilityHint("Finish onboarding and go to the app")
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .homeBackground()
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    OnboardingView()
}
