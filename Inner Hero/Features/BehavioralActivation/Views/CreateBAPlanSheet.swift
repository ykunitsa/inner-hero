import SwiftUI

struct CreateBAPlanSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // TODO: Implement BA plan creation form
            Text(String(localized: "Create plan"))
                .navigationTitle(String(localized: "New plan"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "Cancel")) { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    CreateBAPlanSheet()
}
