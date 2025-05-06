/**
 * Firebase Cloud Functions for LokoPong
 * 
 * This module handles sending push notifications via Firebase Cloud Messaging (FCM)
 * when notifications are added to the Firestore database.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function that sends push notifications when a new document is created in the
 * notifications collection.
 * 
 * The notification document should contain:
 * - title: Title of the notification
 * - body: Body text of the notification
 * - Either topic: A topic name to broadcast to, OR token: An individual device token
 * - Additional data fields as needed
 */
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notificationData = snapshot.data();
      const notificationId = context.params.notificationId;
      
      // Validate required fields
      if (!notificationData.title || !notificationData.body) {
        console.error('Notification missing required fields (title or body)');
        await updateNotificationStatus(notificationId, 'error', 'Missing required fields');
        return null;
      }
      
      // Prepare FCM message
      const message = {
        notification: {
          title: notificationData.title,
          body: notificationData.body
        },
        data: {}
      };
      
      // Add any additional data fields to the data payload
      // (excluding fields used for notification control)
      const excludeFields = ['title', 'body', 'topic', 'token', 'timestamp', 'status'];
      Object.keys(notificationData).forEach(key => {
        if (!excludeFields.includes(key)) {
          message.data[key] = String(notificationData[key]);
        }
      });
      
      // Determine if this is a topic broadcast or a direct notification
      let response;
      if (notificationData.topic) {
        // Topic notification - send to all subscribed devices
        message.topic = notificationData.topic;
        response = await admin.messaging().send(message);
        console.log(`Successfully sent topic notification to ${notificationData.topic}: ${response}`);
      } else if (notificationData.token) {
        // Direct notification - send to a specific device
        message.token = notificationData.token;
        response = await admin.messaging().send(message);
        console.log(`Successfully sent notification to token: ${response}`);
      } else {
        // If neither topic nor token is specified, try to send to all registered devices
        const deviceTokens = await getAllDeviceTokens();
        
        if (deviceTokens.length === 0) {
          console.error('No device tokens found and no topic specified');
          await updateNotificationStatus(notificationId, 'error', 'No recipients available');
          return null;
        }
        
        // For many tokens, we should use sendMulticast instead
        if (deviceTokens.length > 1) {
          message.tokens = deviceTokens;
          response = await admin.messaging().sendMulticast(message);
          console.log(`Sent multicast notification to ${deviceTokens.length} devices. Success: ${response.successCount}, Failure: ${response.failureCount}`);
        } else {
          message.token = deviceTokens[0];
          response = await admin.messaging().send(message);
          console.log(`Sent single notification to device: ${response}`);
        }
      }
      
      // Update the notification document to mark it as sent
      await updateNotificationStatus(notificationId, 'sent', response);
      return null;
      
    } catch (error) {
      console.error('Error sending notification:', error);
      await updateNotificationStatus(context.params.notificationId, 'error', error.message);
      return null;
    }
  });

/**
 * Helper function to update the status of a notification document
 */
async function updateNotificationStatus(notificationId, status, detail = null) {
  const updateData = {
    status: status,
    processedAt: admin.firestore.FieldValue.serverTimestamp()
  };
  
  if (detail) {
    updateData.statusDetail = detail;
  }
  
  await admin.firestore().collection('notifications').doc(notificationId).update(updateData);
}

/**
 * Helper function to get all registered device tokens
 */
async function getAllDeviceTokens() {
  const tokensSnapshot = await admin.firestore().collection('deviceTokens').get();
  
  if (tokensSnapshot.empty) {
    return [];
  }
  
  // Extract the tokens from the documents
  const tokens = [];
  tokensSnapshot.forEach(doc => {
    const data = doc.data();
    if (data.token) {
      tokens.push(data.token);
    }
  });
  
  return tokens;
} 