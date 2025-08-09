const functions = require("firebase-functions");
const admin = require("firebase-admin");

// IMPORTANT: Use Firebase environment configuration to store your secret key.
// Do not hardcode it in your source code.
// Run: firebase functions:config:set stripe.secret="sk_test_..."
const stripe = require("stripe")(functions.config().stripe.secret);

admin.initializeApp();

/**
 * Creates a Stripe Payment Intent.
 *
 * This function must be called by an authenticated user.
 *
 * @param {object} data The data passed to the function.
 * @param {number} data.amount The amount for the payment in the smallest currency unit (e.g., paise/cents).
 * @param {string} data.currency The currency code (e.g., 'inr', 'usd').
 * @param {string} [data.invoiceId] Optional: The ID of the invoice being paid.
 * @param {object} context The context of the function call.
 * @returns {Promise<{clientSecret: string}>} An object containing the client secret for the Payment Intent.
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // 1. Ensure the user is authenticated.
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { amount, currency, invoiceId } = data;

  // 2. Validate the input data.
  if (!Number.isInteger(amount) || amount <= 0 || !currency) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a positive integer 'amount' and a 'currency' string."
    );
  }

  try {
    // 3. Create a Payment Intent with the order amount and currency.
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        userId: context.auth.uid,
        invoiceId: invoiceId || "N/A",
      },
    });

    // 4. Send the client secret back to the client.
    return { clientSecret: paymentIntent.client_secret };
  } catch (error) {
    console.error("Stripe Error:", error);
    throw new functions.https.HttpsError("internal", "Unable to create payment intent.");
  }
});
/**
 * Cloud Function that triggers when a new announcement is created in the
 * Realtime Database at `/announcements/{pushId}`.
 */
exports.sendAnnouncementNotification = functions.database
  .ref("/announcements/{pushId}")
  .onCreate(async (snapshot, context) => {
    // Get the data for the new announcement
    const announcement = snapshot.val();

    const { title, body, topic, fcmToken } = announcement;

    // Validate the announcement data
    if (!title || !body) {
      console.log("Announcement is missing a title or body, exiting.");
      return null;
    }

    // Construct the FCM payload
    const payload = {
      notification: {
        title: title,
        body: body,
        sound: "default",
      },
      // This data is what your Flutter app receives when a notification is tapped
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        // You can add any other custom data you need in the app
        // e.g., 'screen': '/announcements'
      },
    };

    try {
      if (topic) {
        // Send a notification to a specific topic
        console.log(`Sending notification to topic: ${topic}`);
        await admin.messaging().sendToTopic(topic, payload);
      } else if (fcmToken) {
        // Send a notification to a specific device
        console.log(`Sending notification to token: ${fcmToken}`);
        await admin.messaging().sendToDevice(fcmToken, payload);
      } else {
        console.log(
          "No topic or fcmToken provided. Cannot send notification."
        );
        return null;
      }

      console.log("Notification sent successfully!");
    } catch (error) {
      console.error("Error sending notification:", error);
    }

    // Clean up the announcement from the database after sending
    // to prevent re-triggering on function restarts.
    return snapshot.ref.remove();
  });