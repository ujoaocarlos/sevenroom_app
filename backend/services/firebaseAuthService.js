"use strict";

const admin = require("firebase-admin");

let appInitialized = false;

function initializeFirebase() {
  if (appInitialized) return;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
    });
  } else {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || "app-7room",
    });
  }

  appInitialized = true;
}

async function verifyFirebaseToken(token) {
  initializeFirebase();
  return admin.auth().verifyIdToken(token);
}

async function getFirebaseUserRole(uid) {
  initializeFirebase();
  const snapshot = await admin.firestore().collection("users").doc(uid).get();
  return snapshot.exists ? snapshot.data().role || "user" : "user";
}

module.exports = { verifyFirebaseToken, getFirebaseUserRole };
