importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAmWiD0s4mbRQoj9MygF_rWtakyDg0-GC0',
  authDomain: 'theword-6f685.firebaseapp.com',
  projectId: 'theword-6f685',
  storageBucket: 'theword-6f685.firebasestorage.app',
  messagingSenderId: '361079807821',
  appId: '1:361079807821:web:536160a4bb723d99236104',
  measurementId: 'G-EPXEBBJGPM',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title =
    (payload.notification && payload.notification.title) || 'The Word Center';
  const options = {
    body: (payload.notification && payload.notification.body) || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});
