# LokoPong Firebase Cloud Functions

This directory contains Firebase Cloud Functions for the LokoPong app, specifically for handling push notifications.

## Setup

1. Install the Firebase CLI:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Initialize Firebase in the root directory of your project (not in this functions folder):
   ```
   firebase init
   ```
   - Select "Functions" when prompted
   - Choose your Firebase project
   - Select JavaScript when asked
   - Say "No" to ESLint
   - Say "Yes" to installing dependencies

## Deploying

To deploy the functions:

```
firebase deploy --only functions
```

## Push Notification Flow

1. When a match is updated, a notification document is created in Firestore in the `notifications` collection.
2. The Cloud Function `sendNotification` watches this collection for new documents.
3. When a new notification document is created, the function:
   - Validates the notification data
   - Constructs an FCM message
   - Sends the notification via FCM to either:
     - A specific device token
     - A topic (e.g., "tournaments")
     - All registered device tokens
   - Updates the notification document with status information

## Notification Document Format

```javascript
{
  "title": "Match Update: Next Up",        // Required: Title of the notification
  "body": "Next up: Team A vs Team B",     // Required: Body text of the notification
  "topic": "tournaments",                  // Optional: Topic to send to (all subscribers)
  "token": "device_token_here",            // Optional: Single device token to send to
  "status": "pending",                     // Status: pending, sent, error
  "timestamp": Timestamp,                  // When the notification was created
  // Additional data fields for the notification payload:
  "type": "match_update",
  "completedMatchId": "match_id",
  "nextMatchId": "next_match_id"
} 