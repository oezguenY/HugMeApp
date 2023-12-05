//
//  HugRequest.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 18.08.22.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

struct HugRequest: Codable, Equatable, TimestampSortable {
    let hugrequestSenderUID: String
    let hugrequestReceiverUID: String
    let sender: String
    let receiver: String
    let description: String?
    var senderProfileImgUrl: String?
    var hugRequestImage: String?
    let gif: String?
    let timestamp: Timestamp
    let textLocation: CGPoint?
    let senderScreenWidth: Double?
    let senderScreenHeight: Double?
    let uid: String
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(uid) // Use a property that uniquely identifies each user
        }
}

extension HugRequest {
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

extension HugRequest: Hashable {
static func == (lhs: HugRequest, rhs: HugRequest) -> Bool {
    return lhs.uid == rhs.uid // Use a property for equality comparison
}
}



