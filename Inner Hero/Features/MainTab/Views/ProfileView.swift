import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.teal)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Inner Hero")
                                .font(.title3.weight(.semibold))
                            Text("Версия 1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Настройки") {
                    NavigationLink {
                        Text("Уведомления")
                            .navigationTitle("Уведомления")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Уведомления", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Конфиденциальность")
                            .navigationTitle("Конфиденциальность")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Конфиденциальность", systemImage: "lock.shield")
                    }
                }
                
                Section("Поддержка") {
                    NavigationLink {
                        Text("Помощь")
                            .navigationTitle("Помощь")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Помощь", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink {
                        Text("О приложении")
                            .navigationTitle("О приложении")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("О приложении", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
