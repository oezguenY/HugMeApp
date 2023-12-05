//
//  Profile.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 18.08.22.
//

import Foundation
import FirebaseFirestoreSwift

struct AppUser: Codable, Equatable {
    var fullName: String
    var userName: String
    var profileImageURL: String
    var friends: [String?]
    var friendrequestsReceived: [String?]
    var friendrequestsSent: [String?]
    var hugrequestsReceived: [String?]
    var hugrequestsSent: [String?]
    var hugsGotten: [String?]
    var hugsGiven: [String?]
    var email: String?
    var uid: String?
    var fcmToken: String?
    var appleUserIdentifier: String?
    var keywordsForLookup: [String] {
        [self.userName.generateStringSequence(), self.fullName.generateStringSequence()].flatMap { $0 }
    }

    
    init(fullName: String, userName: String, email: String?, uid: String?, fcmToken: String?, appleUserIdentifier: String?) {
        self.fullName = fullName
        self.userName = userName
        self.profileImageURL = ""
        self.friends = []
        self.friendrequestsReceived = []
        self.friendrequestsSent = []
        self.hugrequestsReceived = []
        self.hugrequestsSent = []
        self.hugsGotten = []
        self.hugsGiven = []
        self.email = email
        self.uid = uid
        self.fcmToken = fcmToken
        self.appleUserIdentifier = appleUserIdentifier
    }

    init(simplifiedFrom appUser: AppUser) {
        fullName = appUser.fullName
        userName = appUser.userName
        profileImageURL = appUser.profileImageURL
        friends = []
        friendrequestsReceived = []
        friendrequestsSent = []
        hugrequestsReceived = []
        hugrequestsSent = []
        hugsGotten = []
        hugsGiven = []
        email = appUser.email
        uid = appUser.uid
        fcmToken = appUser.fcmToken
    }
    
    enum CodingKeys: String, CodingKey {
        case fullName = "fullname"
        case userName = "username"
        case profileImageURL
        case friendrequestsReceived = "friendrequestsreceived"
        case friendrequestsSent = "friendrequestssent"
        case hugrequestsReceived = "hugrequestsreceived"
        case hugrequestsSent = "hugrequestssent"
        case hugsGotten = "hugsgotten"
        case hugsGiven = "hugsgiven"
        case friends
        case uid
        case email
        case fcmToken
        case appleUserIdentifier
    }
//    
//    func hash(into hasher: inout Hasher) {
//            hasher.combine(uid) // Use a property that uniquely identifies each user
//        }
}

extension AppUser: Hashable {
    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        return lhs.uid == rhs.uid // Use a property for equality comparison
    }
}

extension String {
    func generateStringSequence() -> [String] {
        guard self.count > 0 else { return [] }
        var sequences: [String] = []
        for i in 1...self.count {
            sequences.append(String(self.prefix(i)))
        }
        return sequences
    }
}
