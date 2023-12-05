//
//  Constants.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 29.08.22.
//

import Foundation
import Firebase

struct Constants {
    
    struct Storage {
        static let images = "images"
    }
    
    struct Collections {
        static let UsersCollectionRef: CollectionReference = Firestore.firestore().collection("users")
        static let FriendRequestsCollectionRef: CollectionReference = Firestore.firestore().collection("friendrequests")
        static let HugRequestsCollectionRef: CollectionReference = Firestore.firestore().collection("hugrequests")
        static let HugPostsRef: CollectionReference = Firestore.firestore().collection("hugposts")
        static let UserInfoRef: CollectionReference = Firestore.firestore().collection("userinfo")
    }
    
    struct ViewControllers {
        
        static let SEARCH_VC = "SearchVC"
    }
    
    struct Firebase {
        
        static let USERS = "users"
        static let USERNAME = "username"
        static let EMAIL = "email"
        static let UID = "uid"
        static let FULLNAME = "fullname"
        static let FRIENDS = "friends"
        static let FRIENDREQUESTS = "friendrequests"
        static let HUGS = "hugs"
        static let RATING = "rating"
        static let PROFILEIMGURL = "profileImageURL"
        static let HUGREQUESTS = "hugrequests"
    }
    
    
}
