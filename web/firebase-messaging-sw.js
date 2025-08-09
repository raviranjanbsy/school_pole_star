importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyBDNV7CbHTaIbkQ2hi0Jwk0HZCq5IrdsIw",
  authDomain: "school-mang-ivar.firebaseapp.com",
  databaseURL: "https://school-mang-ivar-default-rtdb.firebaseio.com",
  projectId: "school-mang-ivar",
  storageBucket: "school-mang-ivar.firebasestorage.app",
  messagingSenderId: "1087394897321",
  appId: "1:1087394897321:web:bf6e0b37dd98ef3c3578b8"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();