/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
/*
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
*/
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleAuth } = require('google-auth-library');
const fetch = require('node-fetch');

admin.initializeApp();

// Function to get a fresh OAuth token dynamically
async function getAccessToken() {
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token;
}

// Utility function to send FCM notification using HTTP v1 API
async function sendNotification(fcmToken, title, body) {
  try {
    const accessToken = await getAccessToken();
    const message = {
      message: {
        notification: {
          title: title,
          body: body,
        },
        token: fcmToken,
      },
    };

    const response = await fetch(
      'https://fcm.googleapis.com/v1/projects/hikenity/messages:send',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      }
    );

    if (response.ok) {
      console.log(`Notification sent successfully to token: ${fcmToken}`);
    } else {
      const errorText = await response.text();
      console.error(`Error sending notification: ${errorText}`);
    }
  } catch (error) {
    console.error(`Error in sendNotification: ${error}`);
  }
}

// **Remind Participants & Auto-Unlist Functionality**
exports.remindAndUnlistParticipants = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const cutoffDate = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 4 * 24 * 60 * 60 * 1000
      );

      // Fetch trips happening within 4 days
      const tripsSnapshot = await admin
        .firestore()
        .collection('trips')
        .where('date', '<=', cutoffDate)
        .get();
      if (tripsSnapshot.empty) {
        console.log('No trips found within the reminder/unlisting period.');
        return null;
      }

      for (const tripDoc of tripsSnapshot.docs) {
        const tripData = tripDoc.data();
        const tripId = tripDoc.id;

        if (!tripData.placeName) {
          console.warn(`Trip ${tripId} is missing placeName. Skipping.`);
          continue;
        }

        // Fetch participants who haven't confirmed the trip
        const participantsSnapshot = await admin
          .firestore()
          .collection('bookings')
          .where('tripId', '==', tripId)
          .where('status', '==', 'booked') // Not confirmed
          .get();

        if (participantsSnapshot.empty) {
          console.log(`No unconfirmed participants for trip: ${tripData.placeName}`);
          continue;
        }

        for (const participantDoc of participantsSnapshot.docs) {
          const participantData = participantDoc.data();
          const bookingId = participantDoc.id;
          const fcmToken = participantData.fcmToken;

          // Notify participant
          if (fcmToken) {
            const title = 'Trip Reminder';
            const body = `Don't forget to confirm your trip for ${tripData.placeName}!`;
            await sendNotification(fcmToken, title, body);
          } else {
            console.warn(
              `Participant ${bookingId} is missing FCM token. Skipping notification.`
            );
          }

          // Auto-unlist participant if past the cutoff date
          const tripDate = tripData.date.toDate();
          if (Date.now() > tripDate.getTime() - 4 * 24 * 60 * 60 * 1000) {
            console.log(
              `Unlisting participant ${bookingId} for trip ${tripId} due to no confirmation.`
            );
            await admin
              .firestore()
              .collection('bookings')
              .doc(bookingId)
              .update({ status: 'unlisted' });

            // Decrease participant count in the trip document
            await admin.firestore().runTransaction(async (transaction) => {
              const tripRef = admin.firestore().collection('trips').doc(tripId);
              const tripSnapshot = await transaction.get(tripRef);

              if (tripSnapshot.exists) {
                const participantCount = tripSnapshot.data().participantCount || 0;
                transaction.update(tripRef, {
                  participantCount: participantCount > 0 ? participantCount - 1 : 0,
                });
              }
            });
          }
        }
      }
    } catch (error) {
      console.error(`Error in remindAndUnlistParticipants function: ${error}`);
    }
    return null;
  });

// **Notify the Organizer When a New Booking is Made**
exports.notifyOrganizerOnBooking = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    try {
      const bookingData = snap.data();
      const tripId = bookingData.tripId;

      if (!tripId) {
        console.warn('Booking data is missing tripId. Skipping notification.');
        return null;
      }

      // Fetch trip details
      const tripDoc = await admin.firestore().collection('trips').doc(tripId).get();
      const tripData = tripDoc.data();

      if (!tripData) {
        console.warn(`Trip ${tripId} does not exist. Skipping notification.`);
        return null;
      }

      const organizerId = tripData.organizerId;

      if (!organizerId) {
        console.warn(`Trip ${tripId} is missing organizerId. Skipping notification.`);
        return null;
      }

      // Fetch organizer's details
      const organizerDoc = await admin
        .firestore()
        .collection('users')
        .doc(organizerId)
        .get();
      const organizerData = organizerDoc.data();

      if (organizerData && organizerData.fcmToken) {
        const title = 'New Booking Alert';
        const body = `A new participant has booked your trip: ${tripData.placeName}.`;
        await sendNotification(organizerData.fcmToken, title, body);
      } else {
        console.warn(
          `Organizer ${organizerId} is missing FCM token. Skipping notification.`
        );
      }
    } catch (error) {
      console.error(`Error in notifyOrganizerOnBooking function: ${error}`);
    }
    return null;
  });

// **Notify Admin on New Certificate Upload**
exports.notifyAdminsOnPendingApproval = functions.firestore
  .document('organisers/{organiserId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();

      // Check if the certificate URL was updated
      if (!before || !after || before.certificateUrl === after.certificateUrl) {
        console.log('No relevant change in certificate status. Skipping notification.');
        return null;
      }

      // Ensure the new certificate URL exists
      if (!after.certificateUrl) {
        console.warn('New certificate URL is missing. Skipping notification.');
        return null;
      }

      // Fetch all admins
      const adminSnapshot = await admin.firestore().collection('admins').get();

      if (adminSnapshot.empty) {
        console.log('No admins found. Skipping notification.');
        return null;
      }

      const title = 'New Certificate Pending Approval';
      const body = `The organiser "${after.fullName || 'Unknown'}" has uploaded a certificate for approval.`;

      // Prepare all notification promises
      const notificationPromises = adminSnapshot.docs.map(async (doc) => {
        const adminData = doc.data();

        if (adminData.fcmToken) {
          await sendNotification(adminData.fcmToken, title, body);
        } else {
          console.warn(`Admin ${doc.id} is missing FCM token. Skipping notification.`);
        }
      });

      // Execute all notifications concurrently
      await Promise.all(notificationPromises);

      console.log('Notifications sent to all relevant admins.');
    } catch (error) {
      console.error(`Error in notifyAdminsOnPendingApproval function: ${error.message}`, error);
    }
    return null;
  });