const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyNewProduct = onDocumentCreated(
  "lubricants/{productId}",
  async (event) => {
    const product = event.data.data();

    // 1. Fetch all customer FCM tokens
    const tokensSnapshot = await admin
      .firestore()
      .collection("fcm_tokens")
      .where("role", "==", "customer")
      .get();

    if (tokensSnapshot.empty) return null;

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    // 2. Send multicast notification
    const message = {
      notification: {
        title: "New Product Available!",
        body: `${product.name} by ${product.brand} is now in PΣTROFY!`,
      },
      data: {
        screen: "shop",
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(
      `✅ Sent: ${response.successCount}, ❌ Failed: ${response.failureCount}`
    );

    // 3. Clean up invalid tokens
    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) {
        batch.delete(tokensSnapshot.docs[idx].ref);
      }
    });

    return batch.commit();
  }
);