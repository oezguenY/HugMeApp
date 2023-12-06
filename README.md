# HugMeApp

This is a social app that enables you to send hugs to your loved ones. 

# Functionality
- Authentication (Sign Up&Log In)
- Apple Sign In
- Google Sign In
- Push Notifications
- Account and Profile Deletion
- Realtime Capabilities
- Paginated Posts Feed (20 posts per fetch)
- Making/Posting pictures & exchanging text & pictures (somewhat like Snapchat)
- Deleting Posts

# Architecture
- MVC (in hindsight, I should have picked MVVM since some VCs are just too large. For instance the ProfileViewVC is at 2.2k lines of code)

# Backend
- Firebase

# Apple Frameworks Used
- Combine (SignUp VC)
- Vision (Functionality for recognizing human faces is commented out at the moment)
- AVFoundation
- UIKit

# Libraries
- FirebaseAuth
- FirebaseMessaging
- FirebaseStorage
- GoogleSignIn
- AuthenticationServices
- Kingfisher
- TOCropViewController
- ImageIO

NOTE: This app is on TestFlight for Beta-Testing. If you want to participate in the Beta, here is the link: https://testflight.apple.com/join/pjvv0zGQ
