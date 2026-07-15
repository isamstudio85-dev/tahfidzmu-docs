// Firebase client for the TahfidzMU Web Admin.
// Uses the SAME Firebase project as the Android app (project: tahfidzmu-db5d9).
// This is purely a client — it never changes Firestore rules/indexes.
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyD2Ko6exFRNxF5a2YcWm6oupub3OegtBBE",
  authDomain: "tahfidzmu-db5d9.firebaseapp.com",
  projectId: "tahfidzmu-db5d9",
  storageBucket: "tahfidzmu-db5d9.firebasestorage.app",
  messagingSenderId: "523716467425",
  appId: "1:523716467425:web:a6cac187e23ce329bff5a0",
  measurementId: "G-QFG27KQ31S",
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;
