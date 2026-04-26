const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ✅ 1. Notify customers when new lubricant product added
exports.notifyNewProduct = onDocumentCreated(
  { document: "lubricants/{productId}", region: "us-central1" },
  async (event) => {
    const product = event.data.data();

    const tokensSnapshot = await admin.firestore()
      .collection("fcm_tokens")
      .where("role", "==", "customer")
      .get();

    if (tokensSnapshot.empty) return null;

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title: "🆕 New Product Available!",
        body: `${product.name} by ${product.brand} is now in stock!`,
      },
      data: { screen: "shop" },
      tokens: tokens,
    });

    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) batch.delete(tokensSnapshot.docs[idx].ref);
    });
    return batch.commit();
  }
);

// ✅ 2. Notify admins when pumper records a new fuel sale
exports.notifyAdminNewSale = onDocumentCreated(
  { document: "fuelSales/{saleId}", region: "us-central1" },
  async (event) => {
    const sale = event.data.data();

    const tokensSnapshot = await admin.firestore()
      .collection("fcm_tokens")
      .where("role", "==", "admin")
      .get();

    if (tokensSnapshot.empty) return null;

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title: "⛽ New Fuel Sale Recorded",
        body: `${sale.pumperName} sold ${sale.soldQuantity}L of ${sale.fuelType} — LKR ${sale.soldTotalPrice.toFixed(2)}`,
      },
      data: { screen: "sales" },
      tokens: tokens,
    });

    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) batch.delete(tokensSnapshot.docs[idx].ref);
    });
    return batch.commit();
  }
);

// ✅ 3. Notify pumper when admin approves their sale
exports.notifyPumperSaleApproved = onDocumentUpdated(
  { document: "fuelSales/{saleId}", region: "us-central1" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status === after.status) return null;

    const pumperId = after.pumperId;
    if (!pumperId) return null;

    const tokenDoc = await admin.firestore()
      .collection("fcm_tokens")
      .doc(pumperId)
      .get();

    if (!tokenDoc.exists) return null;

    let title = "";
    let body = "";

    if (after.status === "payment received") {
      title = "✅ Payment Confirmed!";
      body = `Your ${after.fuelType} sale of LKR ${after.soldTotalPrice.toFixed(2)} has been received by ${after.paymentReceiverName}.`;
    } else if (after.status === "added to safe") {
      title = "🔒 Sale Completed!";
      body = `Your ${after.fuelType} sale of LKR ${after.soldTotalPrice.toFixed(2)} has been added to the safe.`;
    } else {
      return null;
    }

    await admin.messaging().send({
      notification: { title, body },
      data: { screen: "sales" },
      token: tokenDoc.data().token,
    });

    return null;
  }
);

// ✅ 5. NEW: Notify pumper + admin when shift is booked
exports.notifyShiftBooked = onDocumentCreated(
  { document: "shiftSchedule/{shiftId}", region: "us-central1" },
  async (event) => {
    const shift = event.data.data();
    const pumperId = shift.pumperId;

    // --- 5a. Notify the pumper who booked ---
    const pumperTokenDoc = await admin.firestore()
      .collection("fcm_tokens")
      .doc(pumperId)
      .get();

    if (pumperTokenDoc.exists) {
      await admin.messaging().send({
        notification: {
          title: "✅ Shift Booked Successfully!",
          body: `Your ${shift.shiftType} on ${new Date(shift.date.toDate()).toDateString()} at ${shift.pumpNumber} is confirmed!`,
        },
        data: { screen: "shifts" },
        token: pumperTokenDoc.data().token,
      });
    }

    // --- 5b. Notify ALL admins ---
    const adminTokensSnapshot = await admin.firestore()
      .collection("fcm_tokens")
      .where("role", "==", "admin")
      .get();

    if (!adminTokensSnapshot.empty) {
      const adminTokens = adminTokensSnapshot.docs.map((doc) => doc.data().token);

      await admin.messaging().sendEachForMulticast({
        notification: {
          title: "📋 New Shift Scheduled",
          body: `${shift.pumperName} booked ${shift.shiftType} at ${shift.pumpNumber} on ${new Date(shift.date.toDate()).toDateString()}`,
        },
        data: { screen: "shifts" },
        tokens: adminTokens,
      });
    }

    console.log(`✅ Shift notifications sent for pumper: ${shift.pumperName}`);
    return null;
  }
);

// ✅ 6. NEW: Admin sends custom notification to selected user group
exports.sendCustomNotification = onDocumentCreated(
  { document: "adminNotifications/{notifId}", region: "us-central1" },
  async (event) => {
    const notif = event.data.data();
    const { title, body, targetRole } = notif;

    let tokensSnapshot;

    if (targetRole === "all") {
      // Send to everyone
      tokensSnapshot = await admin.firestore()
        .collection("fcm_tokens")
        .get();
    } else {
      // Send to specific role
      tokensSnapshot = await admin.firestore()
        .collection("fcm_tokens")
        .where("role", "==", targetRole)
        .get();
    }

    if (tokensSnapshot.empty) {
      console.log("No tokens found for role:", targetRole);
      return null;
    }

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    const response = await admin.messaging().sendEachForMulticast({
      notification: { title, body },
      data: { screen: "home", type: "custom" },
      tokens: tokens,
    });

    // Update the document with result
    await event.data.ref.update({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      successCount: response.successCount,
      failureCount: response.failureCount,
      status: "sent",
    });

    console.log(`✅ Custom notification sent. Success: ${response.successCount}, Failed: ${response.failureCount}`);

    // Clean up invalid tokens
    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) batch.delete(tokensSnapshot.docs[idx].ref);
    });
    return batch.commit();
  }
);

// ✅ 4. NEW: Notify admin + customer when new order is placed
exports.notifyNewOrder = onDocumentCreated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const order = event.data.data();
    const orderId = event.params.orderId;
    const userId = order.userId;

    // --- 4a. Notify ALL admins ---
    const adminTokensSnapshot = await admin.firestore()
      .collection("fcm_tokens")
      .where("role", "==", "admin")
      .get();

    if (!adminTokensSnapshot.empty) {
      const adminTokens = adminTokensSnapshot.docs.map((doc) => doc.data().token);

      await admin.messaging().sendEachForMulticast({
        notification: {
          title: "🛒 New Order Received!",
          body: `${order.customerName} placed an order for LKR ${order.total}. Order ID: ${orderId}`,
        },
        data: { screen: "orders", orderId: orderId },
        tokens: adminTokens,
      });
    }

    // --- 4b. Notify the customer who placed the order ---
    const customerTokenDoc = await admin.firestore()
      .collection("fcm_tokens")
      .doc(userId)
      .get();

    if (customerTokenDoc.exists) {
      await admin.messaging().send({
        notification: {
          title: "🎉 Order Placed Successfully!",
          body: `Hi ${order.customerName}! Your order of LKR ${order.total} has been placed. We'll prepare it shortly!`,
        },
        data: { screen: "orders", orderId: orderId },
        token: customerTokenDoc.data().token,
      });
    }

    console.log(`✅ Order notifications sent for ${orderId}`);
    return null;
  }
);