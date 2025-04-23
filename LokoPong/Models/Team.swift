import Foundation
import FirebaseFirestore

struct Team: Identifiable {
    let id = UUID()
    var name: String
    var player1Name: String
    var player2Name: String
    var contact1: String
    var contact2: String
    var registrationDate: Date
    var isApproved: Bool
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "player1Name": player1Name,
            "player2Name": player2Name,
            "contact1": contact1,
            "contact2": contact2,
            "registrationDate": registrationDate,
            "isApproved": isApproved
        ]
    }
}
