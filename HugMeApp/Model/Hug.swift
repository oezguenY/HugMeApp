//
//  Hug.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 25.07.23.
//

import Foundation
import Firebase

struct Hug: Codable, Equatable {
    let hugSenderUID: String
    let hugReceiverUID: String
    let senderUsername: String
    let receiverUsername: String
    var senderImageUrl: String?
    var receiverImageUrl: String?
    var hugPicture: String?
    let gif: String
    let timestamp: Timestamp
    let uid: String
}

extension Hug {
    var formattedTimestamp: String {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm | dd/MM/yy"
            return formatter
        }()
        let date = timestamp.dateValue()
        return dateFormatter.string(from: date)
    }
}

extension Hug: Hashable {
static func == (lhs: Hug, rhs: Hug) -> Bool {
    return lhs.uid == rhs.uid // Use a property for equality comparison
}
}


