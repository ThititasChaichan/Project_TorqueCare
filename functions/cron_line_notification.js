/**
 * Cron Script สำหรับรันสแกนวันหมดอายุและส่งแจ้งเตือนเข้า LINE ผ่าน GitHub Actions (ฟรี 100%)
 * รันอัตโนมัติทุกเช้าตามเวลาที่ตั้งไว้
 */

const admin = require("firebase-admin");
const axios = require("axios");
const path = require("path");
const fs = require("fs");

// โหลด Environment Variables จาก .env ถ้ามี (สำหรับการทดสอบในเครื่อง)
try {
  require("dotenv").config({ path: path.join(__dirname, ".env") });
  require("dotenv").config({ path: path.join(__dirname, "..", ".env") });
} catch (e) {
  // บน GitHub Actions หรือ environment อื่น ค่าถูกส่งผ่าน process.env อยู่แล้ว
}

const LINE_CHANNEL_ACCESS_TOKEN = process.env.LINE_CHANNEL_ACCESS_TOKEN;

// 1. กำหนดค่า Firebase Admin
function initFirebase() {
  if (admin.apps.length > 0) return;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log("✅ Firebase Admin initialized with FIREBASE_SERVICE_ACCOUNT Secret");
      return;
    } catch (e) {
      console.error("❌ Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:", e.message);
    }
  }

  const localKeyPath = path.join(__dirname, "serviceAccountKey.json");
  if (fs.existsSync(localKeyPath)) {
    const serviceAccount = require(localKeyPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log("✅ Firebase Admin initialized with local serviceAccountKey.json");
    return;
  }

  // Fallback สำหรับ Google Cloud / Firebase CLI environment
  admin.initializeApp({
    projectId: "flutter-project-torque-85cc2",
  });
  console.log("ℹ️ Firebase Admin initialized with default credentials");
}

// 2. คำนวณวันที่ตามเวลาประเทศไทย (UTC+7)
function getBangkokToday() {
  const now = new Date();
  const utc = now.getTime() + now.getTimezoneOffset() * 60000;
  const bangkokTime = new Date(utc + 3600000 * 7);
  return new Date(bangkokTime.getFullYear(), bangkokTime.getMonth(), bangkokTime.getDate());
}

// 3. ฟังก์ชันยิง LINE Push Message
async function sendLinePush(lineUserId, text) {
  if (!LINE_CHANNEL_ACCESS_TOKEN) {
    console.error("❌ LINE_CHANNEL_ACCESS_TOKEN is missing!");
    return false;
  }

  const url = "https://api.line.me/v2/bot/message/push";
  const payload = {
    to: lineUserId,
    messages: [
      {
        type: "text",
        text: text,
      },
    ],
  };

  try {
    const res = await axios.post(url, payload, {
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
      },
    });
    return res.status === 200;
  } catch (err) {
    console.error("❌ Error sending to LINE:", err.response ? err.response.data : err.message);
    return false;
  }
}

// 4. สแกนและส่งแจ้งเตือน
async function runNotificationCron() {
  initFirebase();
  const db = admin.firestore();

  const today = getBangkokToday();
  console.log(`📅 เริ่มรันสแกนวันหมดอายุประจำวันที่: ${today.toLocaleDateString("th-TH")}`);

  // ค้นหาผู้ใช้ทั้งหมดที่ผูก LINE ไว้
  const usersSnap = await db.collection("users").where("isLineLinked", "==", true).get();
  console.log(`👥 พบผู้ใช้ที่ผูก LINE ทั้งหมด: ${usersSnap.size} คน`);

  const structure = {
    เอกสาร: ["พ.ร.บ.", "ภาษีประจำปี", "ใบขับขี่", "ตรวจสภาพรถ", "ประกันภัย"],
    บริการ: ["ถ่ายน้ำมันเครื่อง", "เปลี่ยนยาง", "เปลี่ยนผ้าเบรก", "เช็คระยะ"],
  };

  for (const userDoc of usersSnap.docs) {
    const userData = userDoc.data();
    const uid = userDoc.id;
    const lineUserId = userData.lineUserId;

    if (!lineUserId) continue;

    console.log(`\n🔍 กำลังตรวจสอบข้อมูลของผู้ใช้: ${userData.username || uid}`);

    // ดึงข้อมูลรถของผู้ใช้คนนี้
    const motosSnap = await db.collection("users").doc(uid).collection("motos").get();
    const motoMap = {};
    motosSnap.forEach((mDoc) => {
      const m = mDoc.data();
      motoMap[mDoc.id] = `${m.brand || ""} ${m.model || ""} (${m.plate || ""})`.trim();
    });

    const matchingAlerts = [];

    // วนลูปตรวจเอกสาร & บริการ
    for (const [category, types] of Object.entries(structure)) {
      for (const type of types) {
        // 1) User level (เช่น ใบขับขี่)
        const userNotiSnap = await db
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(category)
          .collection(type)
          .get();

        userNotiSnap.forEach((doc) => {
          checkAndCollectAlert(doc.data(), type, category, "🪪 ข้อมูลเอกสารผู้ขับขี่", today, matchingAlerts);
        });

        // 2) Moto level (สำหรับรถแต่ละคัน)
        for (const [motoId, motoLabel] of Object.entries(motoMap)) {
          const motoNotiSnap = await db
            .collection("users")
            .doc(uid)
            .collection("motos")
            .doc(motoId)
            .collection("notifications")
            .doc(category)
            .collection(type)
            .get();

          motoNotiSnap.forEach((doc) => {
            checkAndCollectAlert(doc.data(), type, category, `🏍️ รถ: ${motoLabel}`, today, matchingAlerts);
          });
        }
      }
    }

    if (matchingAlerts.length > 0) {
      console.log(`📌 พบรายการที่เข้าเงื่อนไข ${matchingAlerts.length} รายการสำหรับ ${lineUserId}`);

      // สร้างข้อความแจ้งเตือนสรุป
      const buffer = [];
      buffer.push("🔔 แจ้งเตือนจาก TorqueCare");
      buffer.push("--------------------------------");

      for (const alert of matchingAlerts) {
        buffer.push(`\n${alert.title}`);
        buffer.push(` • ${alert.type} : ${alert.body}`);
        if (alert.label) buffer.push(`   (${alert.label})`);
      }

      buffer.push("\n--------------------------------");
      buffer.push("💡 อย่าลืมตรวจเช็คและดำเนินการเพื่อความปลอดภัยนะครับ 🏍️💨");

      const messageText = buffer.join("\n");
      const ok = await sendLinePush(lineUserId, messageText);
      if (ok) {
        console.log(`✅ ส่งเข้า LINE สำเร็จ: ${lineUserId}`);
      } else {
        console.log(`❌ ส่งเข้า LINE ไม่สำเร็จ: ${lineUserId}`);
      }
    } else {
      console.log(`ℹ️ ไม่มีรายการที่ตรงกับเงื่อนไขในวันนี้สำหรับผู้ใช้รายนี้`);
    }
  }

  console.log("\n🎉 รันเสร็จสิ้นเรียบร้อยแล้ว");
}

function checkAndCollectAlert(data, type, category, label, today, list) {
  if (!data || !data.expiry_date) return;

  const expiryDate = data.expiry_date.toDate();
  const expiryDay = new Date(expiryDate.getFullYear(), expiryDate.getMonth(), expiryDate.getDate());

  // คำนวณจำนวนวันที่ต่างกัน
  const diffDays = Math.round((expiryDay - today) / (1000 * 60 * 60 * 24));
  const dateStr = expiryDate.toLocaleDateString("th-TH");

  // เงื่อนไขเดียวกับ Local Notification:
  // - เลยกำหนดแล้ว: diffDays < 0
  // - ครบกำหนดวันนี้: diffDays === 0
  // - อีก 3 วัน: diffDays === 3
  // - อีก 7 วัน: diffDays === 7
  if (diffDays < 0) {
    list.push({
      type,
      category,
      label,
      title: `⚠️ เลยกำหนดแล้ว: ${type}`,
      body: `หมดอายุตั้งแต่ ${dateStr} โปรดรีบดำเนินการ`,
    });
  } else if (diffDays === 0) {
    list.push({
      type,
      category,
      label,
      title: `ใกล้หมดอายุ: ${type} (วันนี้!)`,
      body: `จะหมดอายุในวันที่ ${dateStr} โปรดเตรียมตัวดำเนินการ`,
    });
  } else if (diffDays === 3) {
    list.push({
      type,
      category,
      label,
      title: `ใกล้หมดอายุ: ${type} (อีก 3 วัน)`,
      body: `จะหมดอายุในวันที่ ${dateStr} โปรดเตรียมตัวดำเนินการ`,
    });
  } else if (diffDays === 7) {
    list.push({
      type,
      category,
      label,
      title: `ใกล้หมดอายุ: ${type} (อีก 7 วัน)`,
      body: `จะหมดอายุในวันที่ ${dateStr} โปรดเตรียมตัวดำเนินการ`,
    });
  }
}

// สั่งรันเมื่อเรียกใช้ไฟล์นี้โดยตรง
if (require.main === module) {
  runNotificationCron().catch((err) => {
    console.error("Fatal Error:", err);
    process.exit(1);
  });
}

module.exports = { runNotificationCron };
