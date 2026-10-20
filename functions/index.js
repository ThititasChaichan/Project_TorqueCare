/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const axios = require("axios");
const { defineSecret } = require("firebase-functions/params");
const lineAccessToken = defineSecret("LINE_CHANNEL_ACCESS_TOKEN");

admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const LINE_CHANNEL_ACCESS_TOKEN = process.env.LINE_CHANNEL_ACCESS_TOKEN;

// ฟังก์ชันนี้จะเฝ้าดูการเปลี่ยนแปลงใน collection 'users'
exports.sendWelcomeLineMessage = functions.runWith({ secrets: [lineAccessToken] })
  .firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    if (newValue.lineUserId && newValue.lineUserId !== previousValue.lineUserId) {
      const lineId = newValue.lineUserId;

      const messagePayload = {
        to: lineId,
        messages: [
          {
            type: "text",
            text: "🎉 ยินดีต้อนรับสู่ Moto App! ระบบได้ผูกบัญชีเรียบร้อยแล้ว ต่อจากนี้เราจะคอยแจ้งเตือนค่าซ่อมบำรุงให้คุณเองครับ 🏍️"
          }
        ]
      };

      try {
        await axios.post(
          "https://api.line.me/v2/bot/message/push",
          messagePayload,
          {
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`
            }
          }
        );
        console.log("✅ ส่งข้อความต้อนรับสำเร็จสำหรับ:", lineId);
      } catch (error) {
        console.error("❌ ส่งข้อความล้มเหลว:", error);
      }
    }
    return null;
  });
