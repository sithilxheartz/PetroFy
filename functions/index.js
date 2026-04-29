const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const { addDays, startOfWeek, getDay } = require("date-fns");
const admin = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────────────────────
// ✅ 1. Notify customers when new lubricant product added
// ─────────────────────────────────────────────────────────────
exports.notifyNewProduct = onDocumentCreated(
  { document: "lubricants/{productId}", region: "us-central1" },
  async (event) => {
    const product = event.data.data();
    const tokensSnapshot = await admin.firestore()
      .collection("fcm_tokens").where("role", "==", "customer").get();
    if (tokensSnapshot.empty) return null;
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);
    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title: "New Product Available!",
        body: `${product.name} by ${product.brand} is now in stock!`,
      },
      data: { screen: "shop" },
      tokens,
    });
    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) batch.delete(tokensSnapshot.docs[idx].ref);
    });
    return batch.commit();
  }
);

// ─────────────────────────────────────────────────────────────
// ✅ 2. Notify admins when pumper records a new fuel sale
// ─────────────────────────────────────────────────────────────
exports.notifyAdminNewSale = onDocumentCreated(
  { document: "fuelSales/{saleId}", region: "us-central1" },
  async (event) => {
    const sale = event.data.data();
    const tokensSnapshot = await admin.firestore()
      .collection("fcm_tokens").where("role", "==", "admin").get();
    if (tokensSnapshot.empty) return null;
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);
    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title: "New Fuel Sale Recorded!",
        body: `${sale.pumperName} sold ${sale.soldQuantity}L of ${sale.fuelType} — LKR ${sale.soldTotalPrice.toFixed(2)}`,
      },
      data: { screen: "sales" },
      tokens,
    });
    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) batch.delete(tokensSnapshot.docs[idx].ref);
    });
    return batch.commit();
  }
);

// ─────────────────────────────────────────────────────────────
// ✅ 3. Notify pumper when admin approves their sale
// ─────────────────────────────────────────────────────────────
exports.notifyPumperSaleApproved = onDocumentUpdated(
  { document: "fuelSales/{saleId}", region: "us-central1" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === after.status) return null;
    const pumperId = after.pumperId;
    if (!pumperId) return null;
    const tokenDoc = await admin.firestore()
      .collection("fcm_tokens").doc(pumperId).get();
    if (!tokenDoc.exists) return null;
    let title = "", body = "";
    if (after.status === "payment received") {
      title = "Fuel Payment Confirmed!";
      body = `Your ${after.fuelType} sale of LKR ${after.soldTotalPrice.toFixed(2)} has been received by ${after.paymentReceiverName}.`;
    } else if (after.status === "added to safe") {
      title = "Fuel Sale Completed!";
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

// ─────────────────────────────────────────────────────────────
// ✅ 4. Notify admin + customer when new order is placed
// ─────────────────────────────────────────────────────────────
exports.notifyNewOrder = onDocumentCreated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const order = event.data.data();
    const orderId = event.params.orderId;
    const userId = order.userId;
    const adminTokensSnapshot = await admin.firestore()
      .collection("fcm_tokens").where("role", "==", "admin").get();
    if (!adminTokensSnapshot.empty) {
      const adminTokens = adminTokensSnapshot.docs.map((doc) => doc.data().token);
      await admin.messaging().sendEachForMulticast({
        notification: {
          title: "New Online Order Received!",
          body: `${order.customerName} placed an order for LKR ${order.total}. Order ID: ${orderId}`,
        },
        data: { screen: "orders", orderId },
        tokens: adminTokens,
      });
    }
    const customerTokenDoc = await admin.firestore()
      .collection("fcm_tokens").doc(userId).get();
    if (customerTokenDoc.exists) {
      await admin.messaging().send({
        notification: {
          title: "Order Placed Successfully!",
          body: `Hi ${order.customerName}! Your order of LKR ${order.total} has been placed. We'll prepare it shortly!`,
        },
        data: { screen: "orders", orderId },
        token: customerTokenDoc.data().token,
      });
    }
    return null;
  }
);

// ─────────────────────────────────────────────────────────────
// ✅ 5. Notify pumper + admin when shift is booked
// ─────────────────────────────────────────────────────────────
exports.notifyShiftBooked = onDocumentCreated(
  { document: "shiftSchedule/{shiftId}", region: "us-central1" },
  async (event) => {
    const shift = event.data.data();
    const pumperId = shift.pumperId;
    const pumperTokenDoc = await admin.firestore()
      .collection("fcm_tokens").doc(pumperId).get();
    if (pumperTokenDoc.exists) {
      await admin.messaging().send({
        notification: {
          title: "Shift Booked Successfully!",
          body: `Your ${shift.shiftType} on ${new Date(shift.date.toDate()).toDateString()} at ${shift.pumpNumber} is confirmed!`,
        },
        data: { screen: "shifts" },
        token: pumperTokenDoc.data().token,
      });
    }
    const adminTokensSnapshot = await admin.firestore()
      .collection("fcm_tokens").where("role", "==", "admin").get();
    if (!adminTokensSnapshot.empty) {
      const adminTokens = adminTokensSnapshot.docs.map((doc) => doc.data().token);
      await admin.messaging().sendEachForMulticast({
        notification: {
          title: "New Shift Scheduled",
          body: `${shift.pumperName} booked ${shift.shiftType} at ${shift.pumpNumber} on ${new Date(shift.date.toDate()).toDateString()}`,
        },
        data: { screen: "shifts" },
        tokens: adminTokens,
      });
    }
    return null;
  }
);

// ─────────────────────────────────────────────────────────────
// ✅ 6. Admin sends custom notification to selected user group
// ─────────────────────────────────────────────────────────────
exports.sendCustomNotification = onDocumentCreated(
  { document: "adminNotifications/{notifId}", region: "us-central1" },
  async (event) => {
    const notif = event.data.data();
    const { title, body, targetRole } = notif;
    let tokensSnapshot;
    if (targetRole === "all") {
      tokensSnapshot = await admin.firestore().collection("fcm_tokens").get();
    } else {
      tokensSnapshot = await admin.firestore()
        .collection("fcm_tokens").where("role", "==", targetRole).get();
    }
    if (tokensSnapshot.empty) return null;
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);
    const response = await admin.messaging().sendEachForMulticast({
      notification: { title, body },
      data: { screen: "home", type: "custom" },
      tokens,
    });
    await event.data.ref.update({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      successCount: response.successCount,
      failureCount: response.failureCount,
      status: "sent",
    });
    const batch = admin.firestore().batch();
    response.responses.forEach((res, idx) => {
      if (!res.success) batch.delete(tokensSnapshot.docs[idx].ref);
    });
    return batch.commit();
  }
);

// ─────────────────────────────────────────────────────────────
// ✅ 7. Generate Weekly Schedule (Manager triggers from app)
// ─────────────────────────────────────────────────────────────
const PUMPS = [
  "Petrol 01", "Petrol 02",
  "Diesel 01", "Diesel 02",
  "Super Petrol", "Super Diesel",
];
const SHIFTS = ["Day Shift", "Night Shift"];

exports.generateWeeklySchedule = onCall(
  { region: "us-central1" },
  async (request) => {

    // Security — managers only
    if (!request.auth) throw new Error("unauthenticated");
    const callerDoc = await admin.firestore()
      .collection("users").doc(request.auth.uid).get();
    const role = callerDoc.data().role;
    if (!callerDoc.exists || (role !== "manager" && role !== "admin")) {
      throw new Error("permission-denied: Managers and Admins only.");
    }

    // Figure out which week to schedule
    let weekStart;
    if (request.data.startDate) {
      weekStart = new Date(request.data.startDate);
    } else {
      const today = new Date();
      weekStart = startOfWeek(addDays(today, 7), { weekStartsOn: 1 });
    }
    const weekDates = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));

    // Load all available pumper preferences
    const prefsSnapshot = await admin.firestore()
      .collection("pumperPreferences").get();
    const availablePumpers = prefsSnapshot.docs
      .map(doc => doc.data())
      .filter(p => p.isAvailable === true);

    if (availablePumpers.length === 0) {
      return { success: false, message: "No available pumpers found." };
    }

    // Tracking objects
    const shiftCount = {};
    const assignedOnDay = {};
    availablePumpers.forEach(p => {
      shiftCount[p.pumperId] = 0;
      assignedOnDay[p.pumperId] = {};
    });

    // Build the schedule
    const scheduleEntries = [];
    const unassigned = [];

    for (const date of weekDates) {
      const dayIndex = (getDay(date) + 6) % 7;
      const dateString = date.toISOString().split("T")[0];
      const midnight = new Date(date);
      midnight.setHours(0, 0, 0, 0);

      for (const shift of SHIFTS) {
        for (const pump of PUMPS) {
          const candidate = findBestPumper({
            availablePumpers, shiftCount, assignedOnDay,
            dayIndex, dateString, shift, pump,
          });

          if (candidate) {
            const name = await getPumperName(candidate.pumperId);
            scheduleEntries.push({
              pumperId: candidate.pumperId,
              pumperName: name,
              date: admin.firestore.Timestamp.fromDate(midnight),
              shiftType: shift,
              pumpNumber: pump,
              status: "accepted",
              isAutoAssigned: true,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            shiftCount[candidate.pumperId]++;
            if (!assignedOnDay[candidate.pumperId][dateString]) {
              assignedOnDay[candidate.pumperId][dateString] = [];
            }
            assignedOnDay[candidate.pumperId][dateString].push(shift);
          } else {
            unassigned.push({ date: dateString, shift, pump });
          }
        }
      }
    }
// Write to Firestore
    const batch = admin.firestore().batch();
    for (const entry of scheduleEntries) {
      const ref = admin.firestore().collection("shiftSchedule").doc();
      batch.set(ref, entry);
    }
    await batch.commit();

    // ── NOTIFY EACH PUMPER ──
    // Count how many shifts each pumper was assigned this week
    const pumperShiftSummary = {};
    for (const entry of scheduleEntries) {
      if (!pumperShiftSummary[entry.pumperId]) {
        pumperShiftSummary[entry.pumperId] = {
          name: entry.pumperName,
          count: 0,
        };
      }
      pumperShiftSummary[entry.pumperId].count++;
    }

    // Format the week date nicely e.g. "28 Apr"
    const weekLabel = weekStart.toLocaleDateString("en-GB", {
      day: "2-digit",
      month: "short",
    });
    const weekEndDate = addDays(weekStart, 6);
    const weekEndLabel = weekEndDate.toLocaleDateString("en-GB", {
      day: "2-digit",
      month: "short",
    });

    // Send a personal notification to each pumper
    for (const [pumperId, info] of Object.entries(pumperShiftSummary)) {
      try {
        const tokenDoc = await admin.firestore()
          .collection("fcm_tokens")
          .doc(pumperId)
          .get();

        if (!tokenDoc.exists) continue;

        await admin.messaging().send({
          notification: {
            title: "Your Shift Schedule is Ready!",
            body: `You have ${info.count} shift${info.count > 1 ? "s" : ""} scheduled for ${weekLabel} — ${weekEndLabel}. Tap to view.`,
          },
          data: { screen: "my_schedule" },
          token: tokenDoc.data().token,
        });

        console.log(`✅ Notified ${info.name} (${info.count} shifts)`);
      } catch (e) {
        console.log(`⚠️ Could not notify pumper ${pumperId}: ${e.message}`);
      }
    }

    // Also notify manager that generation is complete
// Replace the existing manager notification block with this:
try {
  // Get all admin + manager tokens
  const adminTokens = await admin.firestore()
    .collection("fcm_tokens")
    .where("role", "==", "admin")
    .get();

  const managerTokens = await admin.firestore()
    .collection("fcm_tokens")
    .where("role", "==", "manager")
    .get();

  const allStaffDocs = [
    ...adminTokens.docs,
    ...managerTokens.docs,
  ];

  if (allStaffDocs.length > 0) {
    const staffTokenList = allStaffDocs.map((doc) => doc.data().token);

    await admin.messaging().sendEachForMulticast({
      notification: {
        title: "Shift Schedule Generated",
        body: `${scheduleEntries.length} shifts assigned for ${weekLabel} — ${weekEndLabel}.${unassigned.length > 0 ? ` ⚠️ ${unassigned.length} slots unassigned.` : " All pumps fully staffed!"}`,
      },
      data: { screen: "generate_schedule" },
      tokens: staffTokenList,
    });
  }
} catch (e) {
  console.log(`⚠️ Could not notify staff: ${e.message}`);
}

    return {
      success: true,
      shiftsCreated: scheduleEntries.length,
      unassignedSlots: unassigned,
      weekOf: weekStart.toISOString().split("T")[0],
    };
  }
);

// Scoring algorithm
function findBestPumper({ availablePumpers, shiftCount, assignedOnDay, dayIndex, dateString, shift, pump }) {
  let bestCandidate = null;
  let bestScore = -Infinity;

  for (const pumper of availablePumpers) {
    const id = pumper.pumperId;
    if (shiftCount[id] >= pumper.maxShiftsPerWeek) continue;
    if (pumper.daysOff && pumper.daysOff.includes(dayIndex)) continue;
    const todayShifts = assignedOnDay[id][dateString] || [];
    if (todayShifts.length > 0) {
      if (!pumper.allowConsecutiveShifts) continue;
      if (todayShifts.includes(shift)) continue;
    }
    let score = 0;
    score += (pumper.maxShiftsPerWeek - shiftCount[id]) * 2;
    if (pumper.preferredShift === shift) score += 10;
    if (pumper.preferredShift === "No Preference") score += 3;
    if (pumper.preferredPumps && pumper.preferredPumps.includes(pump)) score += 5;
    score += Math.random() * 0.5;
    if (score > bestScore) {
      bestScore = score;
      bestCandidate = pumper;
    }
  }
  return bestCandidate;
}

// Get pumper full name
async function getPumperName(pumperId) {
  try {
    const doc = await admin.firestore().collection("users").doc(pumperId).get();
    if (doc.exists) {
      const d = doc.data();
      return `${d.firstName} ${d.lastName}`;
    }
    return "Unknown";
  } catch (e) {
    return "Unknown";
  }
}

// ✅ Notify pumper when they receive a swap request
exports.notifySwapRequest = onDocumentCreated(
  { document: "swapRequests/{swapId}", region: "us-central1" },
  async (event) => {
    const swap = event.data.data();

    // Notify the target pumper (Pumper B)
    const tokenDoc = await admin.firestore()
      .collection("fcm_tokens")
      .doc(swap.targetId)
      .get();

    if (!tokenDoc.exists) return null;

    await admin.messaging().send({
      notification: {
        title: "New Shift Swap Request!",
        body: `${swap.requesterName} wants to swap their ${swap.requesterShiftType} (${swap.requesterPump}) with your ${swap.targetShiftType} (${swap.targetPump}).`,
      },
      data: { screen: "swap_requests" },
      token: tokenDoc.data().token,
    });

    return null;
  }
);

// ✅ Notify admin when fuel tank drops below 20% capacity
exports.notifyLowFuelLevel = onDocumentUpdated(
  { document: "fuelTanks/{tankId}", region: "us-central1" },
  async (event) => {
    const before = event.data.before.data();
    const after  = event.data.after.data();

    const capacity        = after.capacity        ?? 0;
    const prevQuantity    = before.currentQuantity ?? 0;
    const currentQuantity = after.currentQuantity  ?? 0;

    if (capacity === 0) return null;

    const prevPercent    = (prevQuantity    / capacity) * 100;
    const currentPercent = (currentQuantity / capacity) * 100;
    const threshold      = 20;

    // Only fire when it CROSSES below 20% — not on every update below 20%
    // This prevents spam notifications
    if (prevPercent >= threshold && currentPercent < threshold) {

      const fuelType       = after.fuelType ?? "Unknown";
      const remainingLiters = currentQuantity.toFixed(0);
      const percentLeft    = currentPercent.toFixed(1);

      console.log(`⚠️ LOW FUEL: ${fuelType} at ${percentLeft}%`);

      // Get all admin tokens
      const adminTokensSnapshot = await admin.firestore()
        .collection("fcm_tokens")
        .where("role", "==", "admin")
        .get();

      // Also get manager tokens
      const managerTokensSnapshot = await admin.firestore()
        .collection("fcm_tokens")
        .where("role", "==", "manager")
        .get();

      // Combine all tokens
      const allDocs = [
        ...adminTokensSnapshot.docs,
        ...managerTokensSnapshot.docs,
      ];

      if (allDocs.length === 0) {
        console.log("No admin/manager tokens found");
        return null;
      }

      const tokens = allDocs.map((doc) => doc.data().token);

      const response = await admin.messaging().sendEachForMulticast({
        notification: {
          title: "⛽ Low Fuel Alert!",
          body: `${fuelType} tank is at ${percentLeft}% — only ${remainingLiters}L remaining. Refill needed!`,
        },
        data: {
          screen: "fuel_dashboard",
          fuelType: fuelType,
        },
        tokens: tokens,
      });

      // Clean up invalid tokens
      const batch = admin.firestore().batch();
      response.responses.forEach((res, idx) => {
        if (!res.success) batch.delete(allDocs[idx].ref);
      });
      await batch.commit();

      console.log(`✅ Low fuel alert sent for ${fuelType}. Success: ${response.successCount}`);
    }

    return null;
  }
);

// ✅ Smart Reorder Suggestion — runs daily at 8:00 AM Sri Lanka time
const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.smartReorderSuggestion = onSchedule(
  {
   // schedule: "0 8 * * *",        // Every day at 8:00 AM
   // schedule: "*/3 * * * *",  // every 2 minutes for testing
schedule: "0 8 * * *",        // Every day at 8:00 AM
timeZone: "Asia/Colombo",
    region: "us-central1",
  },
  async (event) => {
    console.log("🔍 Running smart reorder check...");

    const LEAD_DAYS     = 3;   // Warn 3 days before hitting 20%
    const THRESHOLD_PCT = 0.20; // 20% threshold

    // 1. Get all fuel tanks
    const tanksSnap = await admin.firestore()
      .collection("fuelTanks")
      .get();

    if (tanksSnap.empty) {
      console.log("No tanks found");
      return;
    }

    // 2. Get sales from last 14 days for better average accuracy
    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);

    const salesSnap = await admin.firestore()
      .collection("fuelSales")
      .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
      .get();

    // 3. Group sales by fuel type and calculate daily average
    const salesByFuel = {};
    for (const doc of salesSnap.docs) {
      const sale = doc.data();
      const fuel = sale.fuelType;
      if (!salesByFuel[fuel]) salesByFuel[fuel] = 0;
      salesByFuel[fuel] += sale.soldQuantity ?? 0;
    }

    // Daily average = total sold in 14 days / 14
    const dailyAvgByFuel = {};
    for (const [fuel, total] of Object.entries(salesByFuel)) {
      dailyAvgByFuel[fuel] = total / 14;
    }

    // 4. Get admin + manager FCM tokens
    const [adminSnap, managerSnap] = await Promise.all([
      admin.firestore().collection("fcm_tokens")
        .where("role", "==", "admin").get(),
      admin.firestore().collection("fcm_tokens")
        .where("role", "==", "manager").get(),
    ]);

    const allStaffDocs = [...adminSnap.docs, ...managerSnap.docs];
    const staffTokens  = allStaffDocs.map((d) => d.data().token);

    if (staffTokens.length === 0) {
      console.log("No staff tokens found");
      return;
    }

    // 5. Analyze each tank
    for (const tankDoc of tanksSnap.docs) {
      const tank            = tankDoc.data();
      const fuelType        = tank.fuelType;
      const capacity        = tank.capacity        ?? 0;
      const currentQuantity = tank.currentQuantity ?? 0;

      if (capacity === 0) continue;

      const thresholdQty   = capacity * THRESHOLD_PCT; // 20% of capacity
      const dailyAvg       = dailyAvgByFuel[fuelType] ?? 0;

      // Skip if no sales data for this fuel type
      if (dailyAvg <= 0) {
        console.log(`⚠️ No sales data for ${fuelType}, skipping`);
        continue;
      }

      // How many liters above the threshold?
      const litersAboveThreshold = currentQuantity - thresholdQty;

      // How many days until we hit the threshold?
      const daysUntilThreshold = litersAboveThreshold / dailyAvg;

      const currentPct = ((currentQuantity / capacity) * 100).toFixed(1);

      console.log(
        `${fuelType}: ${currentQuantity}L (${currentPct}%) — ` +
        `avg ${dailyAvg.toFixed(0)}L/day — ` +
        `hits 20% in ${daysUntilThreshold.toFixed(1)} days`
      );

      // 6. Only notify if hitting threshold within LEAD_DAYS
      if (daysUntilThreshold <= LEAD_DAYS && currentQuantity > thresholdQty) {

        // Calculate suggested order quantity
        // Fill to 95% of capacity minus current quantity
        const suggestedOrder = Math.round(
          (capacity * 0.95) - currentQuantity
        );

        // Format the predicted date
        const predictedDate = new Date();
        predictedDate.setDate(
          predictedDate.getDate() + Math.floor(daysUntilThreshold)
        );
        const dateLabel = predictedDate.toLocaleDateString("en-GB", {
          weekday: "long",
          day: "2-digit",
          month: "short",
        });

        const daysLabel = daysUntilThreshold < 1
          ? "today"
          : daysUntilThreshold < 2
          ? "tomorrow"
          : `in ${Math.floor(daysUntilThreshold)} days`;

        // Send notification
        await admin.messaging().sendEachForMulticast({
          notification: {
            title: `⛽ Order Suggestion: ${fuelType}`,
            body:
              `Currently ${currentPct}% (${Math.round(currentQuantity)}L). ` +
              `Burning ~${Math.round(dailyAvg)}L/day. ` +
              `Will hit 20% ${daysLabel} (${dateLabel}). ` +
              `Suggested order: ${suggestedOrder.toLocaleString()}L.`,
          },
          data: {
            screen:       "fuel_dashboard",
            fuelType:     fuelType,
            daysLeft:     String(Math.floor(daysUntilThreshold)),
            suggestedQty: String(suggestedOrder),
          },
          tokens: staffTokens,
        });

        // Also save suggestion to Firestore so it shows in the app
        await admin.firestore().collection("reorderSuggestions").add({
          fuelType,
          currentQuantity,
          currentPercent:   parseFloat(currentPct),
          dailyAvgConsumption: Math.round(dailyAvg),
          daysUntilThreshold: parseFloat(daysUntilThreshold.toFixed(1)),
          predictedDate:    admin.firestore.Timestamp.fromDate(predictedDate),
          suggestedOrderQty: suggestedOrder,
          capacity,
          thresholdQty:     Math.round(thresholdQty),
          createdAt:        admin.firestore.FieldValue.serverTimestamp(),
          status:           "pending", // pending / ordered / dismissed
        });

        console.log(`✅ Reorder suggestion sent for ${fuelType}`);
      }
    }

    console.log("✅ Smart reorder check complete");
  }
);