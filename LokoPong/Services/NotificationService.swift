import Foundation
import FirebaseFirestore
import FirebaseMessaging

/**
 * NotificationService
 *
 * Purpose: Manages tournament notifications using Firebase Cloud Messaging.
 * - Sends match update notifications
 * - Notifies users about upcoming matches
 * - Handles topic subscriptions for broadcasts
 */
class NotificationService {
    private let db = Firestore.firestore()
    
    // Static instance for singleton access
    static let shared = NotificationService()
    
    // Private initializer for singleton pattern
    private init() {}
    
    /**
     * Sends a notification when a match is completed to announce the next match
     * and upcoming matches.
     *
     * @param completedMatch The match that was just completed
     * @param currentRoundIndex The index of the round containing the completed match
     * @param matchIndex The index of the completed match within its round
     * @param allBrackets All tournament brackets, used to find next matches
     */
    func sendMatchCompletionNotification(
        completedMatch: MatchData,
        currentRoundIndex: Int,
        matchIndex: Int,
        allBrackets: [Bracket]
    ) {
        // Step 1: Identify the next match to be played
        let nextMatchInfo = findNextMatchToPlay(
            after: completedMatch,
            currentRoundIndex: currentRoundIndex,
            matchIndex: matchIndex,
            allBrackets: allBrackets
        )
        
        // Step 2: Find the following two matches (if they exist)
        let upcomingMatches = findUpcomingMatches(
            after: nextMatchInfo.match,
            currentRoundIndex: nextMatchInfo.roundIndex,
            matchIndex: nextMatchInfo.matchIndex,
            allBrackets: allBrackets
        )
        
        // Step 3: Construct notification message
        let message = constructNotificationMessage(
            nextMatch: nextMatchInfo.match,
            upcomingMatches: upcomingMatches
        )
        
        // Step 4: Send the notification via Firebase Cloud Messaging to all app users
        sendNotificationToTopic(
            title: "Match Update: Next Up",
            body: message,
            topic: "tournaments",
            data: [
                "type": "match_update",
                "completedMatchId": completedMatch.id,
                "nextMatchId": nextMatchInfo.match.id,
                "roundIndex": String(nextMatchInfo.roundIndex),
                "matchIndex": String(nextMatchInfo.matchIndex)
            ]
        )
    }
    
    /**
     * Finds the next match to be played after a match is completed.
     * This could be the next match in the current round, or the first match
     * of the next round if this was the last match of the current round.
     */
    private func findNextMatchToPlay(
        after completedMatch: MatchData,
        currentRoundIndex: Int,
        matchIndex: Int,
        allBrackets: [Bracket]
    ) -> (match: MatchData, roundIndex: Int, matchIndex: Int) {
        
        if currentRoundIndex >= allBrackets.count {
            // Safety check - if we're out of bounds, return the completed match
            return (completedMatch, currentRoundIndex, matchIndex)
        }
        
        let currentRound = allBrackets[currentRoundIndex]
        
        // Try to find the next match in the current round
        if matchIndex + 1 < currentRound.matches.count {
            let nextMatch = currentRound.matches[matchIndex + 1]
            
            // If the next match doesn't have a winner and both teams are known (not TBD),
            // it's the next match to be played
            if nextMatch.winner.isEmpty && nextMatch.team1 != "TBD" && nextMatch.team2 != "TBD" {
                return (nextMatch, currentRoundIndex, matchIndex + 1)
            }
        }
        
        // If we can't find a suitable match in the current round, or this was the last match,
        // look for the first match in the next round that doesn't have a winner
        if currentRoundIndex + 1 < allBrackets.count {
            let nextRound = allBrackets[currentRoundIndex + 1]
            for (idx, match) in nextRound.matches.enumerated() {
                if match.winner.isEmpty && match.team1 != "TBD" && match.team2 != "TBD" {
                    return (match, currentRoundIndex + 1, idx)
                }
            }
        }
        
        // If we still haven't found a match, just return the current match
        // (the notification system will handle this appropriately)
        return (completedMatch, currentRoundIndex, matchIndex)
    }
    
    /**
     * Finds the next two matches to be played after the "next" match.
     * Returns an array of up to two matches.
     */
    private func findUpcomingMatches(
        after nextMatch: MatchData,
        currentRoundIndex: Int,
        matchIndex: Int,
        allBrackets: [Bracket]
    ) -> [MatchData] {
        var upcomingMatches: [MatchData] = []
        
        // Safety check
        if currentRoundIndex >= allBrackets.count {
            return upcomingMatches
        }
        
        let currentRound = allBrackets[currentRoundIndex]
        
        // Look for matches in the current round after the provided match
        for idx in (matchIndex + 1)..<currentRound.matches.count {
            let match = currentRound.matches[idx]
            if match.winner.isEmpty && match.team1 != "TBD" && match.team2 != "TBD" {
                upcomingMatches.append(match)
                if upcomingMatches.count == 2 {
                    return upcomingMatches
                }
            }
        }
        
        // If we need more matches and there's another round, look there
        if upcomingMatches.count < 2 && currentRoundIndex + 1 < allBrackets.count {
            let nextRound = allBrackets[currentRoundIndex + 1]
            for match in nextRound.matches {
                if match.winner.isEmpty && match.team1 != "TBD" && match.team2 != "TBD" {
                    upcomingMatches.append(match)
                    if upcomingMatches.count == 2 {
                        return upcomingMatches
                    }
                }
            }
        }
        
        return upcomingMatches
    }
    
    /**
     * Constructs a user-friendly notification message announcing the next match
     * and upcoming matches.
     */
    private func constructNotificationMessage(
        nextMatch: MatchData,
        upcomingMatches: [MatchData]
    ) -> String {
        var message = "Next up: \(nextMatch.team1) vs \(nextMatch.team2)"
        
        if !upcomingMatches.isEmpty {
            message += "\n\nComing up soon:"
            
            for (index, match) in upcomingMatches.enumerated() {
                message += "\n• \(match.team1) vs \(match.team2)"
                
                // Limit to 2 upcoming matches to keep the notification concise
                if index == 1 {
                    break
                }
            }
        }
        
        return message
    }
    
    /**
     * Sends a notification to a Firebase topic, which will be delivered to all
     * devices subscribed to that topic.
     */
    private func sendNotificationToTopic(title: String, body: String, topic: String, data: [String: String] = [:]) {
        // Create the notification payload
        var notificationData: [String: Any] = [
            "title": title,
            "body": body,
            "topic": topic,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending" // A Cloud Function will pick this up and send it
        ]
        
        // Add additional data for the notification
        for (key, value) in data {
            notificationData[key] = value
        }
        
        // Store in Firestore for the Cloud Function to process
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error queueing notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification queued successfully")
            }
        }
    }
    
    /**
     * Sends a direct notification to a specific device token
     */
    func sendDirectNotification(title: String, body: String, token: String, data: [String: String] = [:]) {
        // Create the notification payload
        var notificationData: [String: Any] = [
            "title": title,
            "body": body,
            "token": token, // Individual device token
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending"
        ]
        
        // Add additional data for the notification
        for (key, value) in data {
            notificationData[key] = value
        }
        
        // Store in Firestore for the Cloud Function to process
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error queueing direct notification: \(error.localizedDescription)")
            } else {
                print("✅ Direct notification queued successfully")
            }
        }
    }
} 