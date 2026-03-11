import SwiftUI

struct ActivityEditorRow: View {
    @Binding var item: ActivityEditItem
    let index: Int
    let isRemovable: Bool
    let focusState: FocusState<ActivationFormField?>.Binding
    let onDelete: () -> Void
    
    @Environment(\.editMode) private var editMode
    
    private var showsReorderHandle: Bool {
        editMode?.wrappedValue.isEditing == true
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
            if showsReorderHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
                    .alignmentGuide(.firstTextBaseline) { dimensions in
                        dimensions[VerticalAlignment.center]
                    }
                    .accessibilityLabel(String(localized: "Move activity"))
            }
            
            Text("\(index + 1).")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
                .accessibilityHidden(true)
            
            TextField(String(format: String(localized: "Activity %d"), index + 1), text: $item.text)
                .font(.body)
                .focused(focusState, equals: .activity(item.id))
                .accessibilityLabel(String(format: String(localized: "Activity %d"), index + 1))
            
            if isRemovable {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
                .contentShape(Rectangle())
                .alignmentGuide(.firstTextBaseline) { dimensions in
                    dimensions[VerticalAlignment.center]
                }
                .accessibilityLabel(String(format: String(localized: "Delete activity %d"), index + 1))
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    @Previewable @FocusState var focusedField: ActivationFormField?
    
    Form {
        Section {
            ActivityEditorRow(
                item: .constant(ActivityEditItem(text: String(localized: "Warm-up"))),
                index: 0,
                isRemovable: true,
                focusState: $focusedField,
                onDelete: {}
            )
        }
    }
}


