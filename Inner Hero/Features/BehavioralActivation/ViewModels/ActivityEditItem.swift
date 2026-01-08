import Foundation

struct ActivityEditItem: Identifiable, Equatable {
    let id: UUID
    var text: String
    
    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}


