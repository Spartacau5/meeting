// Initialize Firebase
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyDU4LoNcVF63GE1ri0QUCsKgtVFakenw3M",
  authDomain: "verdant-coyote-455921-h1.firebaseapp.com",
  projectId: "verdant-coyote-455921-h1",
  storageBucket: "verdant-coyote-455921-h1.firebasestorage.app",
  messagingSenderId: "987232659668",
  appId: "1:987232659668:web:bd4ad3dc8e7ecfd2d03341"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export { auth }; 