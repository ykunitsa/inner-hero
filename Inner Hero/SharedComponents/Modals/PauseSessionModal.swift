import SwiftUI

// MARK: - Pause Session Modal

struct PauseSessionModal: View {
    let onResume: () -> Void
    let onEnd: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.teal)
                }
                .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text("Вы делаете отлично!")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    
                    Text("Вы уже проделали важную работу. Можете отдохнуть в любое время.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 24)
            
            VStack(alignment: .leading, spacing: 10) {
                supportiveMessage(icon: "checkmark.circle.fill", text: "Делайте перерывы когда нужно")
                supportiveMessage(icon: "heart.circle.fill", text: "Забота о себе - это не слабость")
                supportiveMessage(icon: "star.circle.fill", text: "Каждый шаг - это прогресс")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    onResume()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                        Text("Продолжить сеанс")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.teal)
                    )
                }
                .accessibilityLabel("Продолжить сеанс")
                .accessibilityHint("Дважды нажмите чтобы вернуться к сеансу")
                
                Button {
                    onEnd()
                } label: {
                    Text("Завершить на сегодня")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.tertiarySystemBackground))
                        )
                }
                .accessibilityLabel("Завершить на сегодня")
                .accessibilityHint("Дважды нажмите чтобы завершить сеанс без сохранения")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func supportiveMessage(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.teal)
                .frame(width: 20)
                .accessibilityHidden(true)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
