import { Request, Response } from "express";
import sql from "./db";
import { firebaseAdmin } from "./firebase";

// Initialize Firebase Admin SDK (do this once in your app, not in the function)
// Place this in your app's initialization code
// admin.initializeApp({
//   credential: admin.credential.cert('path/to/serviceAccountKey.json')
// });

export const sendNotification = async (
  userId: string,
  title: string,
  body: string
) => {
  try {
    //console.log("HELLO????");
    const deviceResult = await sql`
      SELECT device_id
      FROM profile
      WHERE id = ${userId};
    `;

    if (deviceResult.length === 0 || !deviceResult[0].device_id) {
      console.log("NO DEVICE");
      return -1;
    }

    const deviceId = deviceResult[0].device_id;

    //console.log("SENDING NOTIF TO", deviceId);

    // Construct the FCM message
    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: deviceId, // The FCM registration token (device ID)
    };

    // Send the notification
    const response = await firebaseAdmin.messaging().send(message);

    //console.log("message response", response);

    return 0;
  } catch (error) {
    console.error("Error sending notification:", error);
    return -1;
  }
};
