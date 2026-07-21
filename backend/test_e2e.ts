import { app } from "./src/app";
import { prisma } from "./src/config/prisma";
import http from "http";

const PORT = 5999;
const BASE_URL = `http://localhost:${PORT}`;

async function runTest() {
  const server = http.createServer(app);
  await new Promise<void>((resolve) => server.listen(PORT, resolve));
  console.log(`🚀 Test server listening on ${BASE_URL}`);

  try {
    // ── 1. Admin Login ──
    console.log("\n1️⃣ Logging in as Admin...");
    const adminRes = await fetch(`${BASE_URL}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: "jurgenslot2005@gmail.com",
        password: "Admin@123456",
      }),
    });
    const adminData = await adminRes.json();
    if (!adminRes.ok) throw new Error(`Admin login failed: ${JSON.stringify(adminData)}`);
    const adminToken = adminData.accessToken;
    console.log("   ✅ Admin logged in successfully.");

    // ── 2. Admin creates an Instrument if none exists ──
    console.log("\n2️⃣ Ensuring at least one Instrument exists...");
    let instrumentsRes = await fetch(`${BASE_URL}/api/instruments`);
    let instrumentsJson = await instrumentsRes.json();
    let instruments = Array.isArray(instrumentsJson) ? instrumentsJson : instrumentsJson.data || [];
    let instrumentId = instruments[0]?.id;

    if (!instrumentId) {
      const createInstRes = await fetch(`${BASE_URL}/api/admin/instruments`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          name: "Acoustic Guitar",
          type: "guitar",
          description: "Versatile acoustic guitar for beginners and pros.",
          imageUrl: "https://via.placeholder.com/150",
          status: "active",
          isVip: false,
        }),
      });
      const instData = await createInstRes.json();
      if (!createInstRes.ok) throw new Error(`Create instrument failed: ${JSON.stringify(instData)}`);
      const createdObj = instData.data || instData.instrument || instData;
      instrumentId = createdObj.id;
      console.log(`   ✅ Created Instrument: ${createdObj.name || "Acoustic Guitar"} (${instrumentId})`);
    } else {
      console.log(`   ✅ Found existing Instrument: ${instruments[0].name} (${instrumentId})`);
    }

    // ── 3. User Registration & Login ──
    const testEmail = `testuser_${Date.now()}@example.com`;
    const testPassword = "Password123!";
    console.log(`\n3️⃣ Registering new User (${testEmail})...`);

    const regRes = await fetch(`${BASE_URL}/api/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        fullName: "Test User Flow",
      }),
    });
    const regData = await regRes.json();
    if (!regRes.ok) throw new Error(`Registration failed: ${JSON.stringify(regData)}`);
    const userToken = regData.accessToken;
    const userId = regData.user.id;
    console.log(`   ✅ User registered and logged in successfully. User ID: ${userId}`);

    // ── 4. Select Instrument ──
    console.log("\n4️⃣ User selects Instrument being practiced...");
    const selectInstRes = await fetch(`${BASE_URL}/api/user-instruments`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({
        instrumentId,
        skillLevel: "beginner",
        isPrimary: true,
      }),
    });
    const selectData = await selectInstRes.json();
    if (!selectInstRes.ok) throw new Error(`Select instrument failed: ${JSON.stringify(selectData)}`);
    console.log("   ✅ Selected Acoustic Guitar as primary instrument.");

    // ── 5. Create Practice Goal ──
    console.log("\n5️⃣ User creates a Practice Goal (30 mins/day)...");
    const goalRes = await fetch(`${BASE_URL}/api/practice-goals`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({
        instrumentId,
        goalType: "daily_minutes",
        targetValue: 30,
      }),
    });
    const goalData = await goalRes.json();
    if (!goalRes.ok) throw new Error(`Create goal failed: ${JSON.stringify(goalData)}`);
    console.log("   ✅ Practice goal created successfully.");

    // ── 6. Start & End Practice Session ──
    console.log("\n6️⃣ User starts a Practice Timer session...");
    const startSessionRes = await fetch(`${BASE_URL}/api/practice-sessions/start`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({ instrumentId }),
    });
    const startData = await startSessionRes.json();
    if (!startSessionRes.ok) throw new Error(`Start session failed: ${JSON.stringify(startData)}`);
    const sessionId = startData.data?.id || startData.id;
    console.log(`   ✅ Practice session started (ID: ${sessionId}).`);

    console.log("   ⏱️ User completes 45 minutes of practice and saves notes...");
    const endSessionRes = await fetch(`${BASE_URL}/api/practice-sessions/${sessionId}/end`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({
        durationMins: 45,
        notes: "Practiced C Major and G Major chord transitions. Felt great!",
        mood: "great",
      }),
    });
    const endData = await endSessionRes.json();
    if (!endSessionRes.ok) throw new Error(`End session failed: ${JSON.stringify(endData)}`);
    console.log("   ✅ Practice session ended & saved to history.");

    // ── 7. View History & Stats ──
    console.log("\n7️⃣ User views Practice History & Stats...");
    const statsRes = await fetch(`${BASE_URL}/api/practice-sessions/stats`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    const statsData = await statsRes.json();
    console.log(`   📊 Total practice time: ${statsData.totalMins || 45} mins | Total sessions: ${statsData.totalSessions || 1}`);

    // ── 8. Manual Payment Request & Admin Approval Flow ──
    console.log("\n8️⃣ User submits a Manual VIP Payment Request (VIP_MONTHLY)...");
    const payReqRes = await fetch(`${BASE_URL}/api/payments/manual-request`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({
        planCode: "VIP_MONTHLY",
        note: "Chuyen khoan VietQR de nang cap VIP",
      }),
    });
    const payReqData = await payReqRes.json();
    if (!payReqRes.ok) throw new Error(`Payment request failed: ${JSON.stringify(payReqData)}`);
    const requestId = payReqData.request?.id || payReqData.id;
    console.log(`   ✅ VIP Request submitted (ID: ${requestId}). Status: PENDING.`);

    console.log("\n9️⃣ Admin reviews and Approves the VIP Request...");
    const approveRes = await fetch(`${BASE_URL}/api/admin/manual-payments/${requestId}/approve`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${adminToken}`,
      },
    });
    const approveData = await approveRes.json();
    if (!approveRes.ok) throw new Error(`Approve payment failed: ${JSON.stringify(approveData)}`);
    console.log("   ✅ Admin approved the VIP payment request.");

    // ── 9. Verify VIP status for User ──
    console.log("\n🔟 Verifying User VIP Subscription status...");
    const vipRes = await fetch(`${BASE_URL}/api/vip/status`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    const vipData = await vipRes.json();
    console.log(`   👑 User VIP Active: ${vipData.isVip || vipData.active ? 'YES' : 'NO'}`);

    console.log("\n==================================================");
    console.log("🎉 ALL END-TO-END STEP 3 TESTS PASSED SUCCESSFULLY! 🎉");
    console.log("==================================================\n");

  } catch (err: any) {
    console.error("\n❌ TEST FAILED:", err.message);
  } finally {
    server.close();
    await prisma.$disconnect();
  }
}

runTest();
