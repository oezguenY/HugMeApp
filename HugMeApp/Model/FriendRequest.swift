//
//  NewFriendRequest.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 10.07.23.
//

import Foundation
import FirebaseFirestoreSwift
import Firebase

struct FriendRequest: Codable, Equatable, TimestampSortable {
    let friendRequestSenderUID: String
    let friendRequestReceiverUID: String
    let senderUsername: String
    let receiverUsername: String
    let timestamp: Timestamp
    let pictureURL: String
    let uid: String
    
    enum CodingKeys: String, CodingKey {
        case friendRequestSenderUID
        case friendRequestReceiverUID
        case senderUsername
        case receiverUsername
        case timestamp
        case pictureURL = "profileImageURL"
        case uid
    }
}

extension FriendRequest {
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

extension FriendRequest: Hashable {
static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
    return lhs.uid == rhs.uid // Use a property for equality comparison
}
}



