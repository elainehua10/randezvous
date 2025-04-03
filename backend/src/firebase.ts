import * as admin from "firebase-admin";
import { ServiceAccount } from "firebase-admin";

export const initializeFirebase = () => {
  // Check if already initialized to prevent multiple initializations
  if (!admin.apps.length) {
    const serviceAccount: ServiceAccount = require("../service-account.json");

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    console.log("Firebase Admin SDK initialized successfully");
  } else {
    console.log("Firebase Admin SDK already initialized");
  }

  return admin;
};

export const firebaseAdmin = initializeFirebase();
