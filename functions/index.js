const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Automatically delivers background FCM push notifications when staff creates
 * a document in `notifications/{notificationId}`.
 * Deploy with: `firebase deploy --only functions` (requires Firebase Blaze plan).
 */
exports.onNotificationCreated = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() || {};

    const audience = data.audience || 'all';
    const targetEmails = new Set(
      (data.targetEmails || []).map((e) => String(e).trim().toLowerCase()),
    );
    const targetUids = new Set(
      (data.targetUids || []).map((u) => String(u).trim()),
    );
    const targetGroupId = String(data.targetGroupId || '');

    const db = getFirestore();
    let groupMemberEmails = new Set();
    if (audience === 'specificGroup' && targetGroupId) {
      const groupSnap = await db.collection('groups').doc(targetGroupId).get();
      if (groupSnap.exists) {
        const members = groupSnap.data().members || [];
        for (const m of members) {
          if (m && m.email) {
            groupMemberEmails.add(String(m.email).trim().toLowerCase());
          }
        }
      }
    }

    const tokenSnap = await db.collection('fcm_tokens').limit(500).get();
    const tokens = [];
    for (const doc of tokenSnap.docs) {
      const t = doc.data();
      if (!t || !t.token) continue;
      const role = String(t.role || 'student');
      const email = String(t.email || '').trim().toLowerCase();
      const uid = String(t.uid || '').trim();

      const matches =
        audience === 'all' ||
        (audience === 'teachersOnly' && role === 'staff') ||
        (audience === 'studentsOnly' && role === 'student') ||
        (audience === 'specificGroup' &&
          (role === 'staff' ||
            groupMemberEmails.has(email) ||
            targetEmails.has(email) ||
            targetUids.has(uid))) ||
        (audience === 'selectedUsers' &&
          (targetEmails.has(email) || targetUids.has(uid)));

      if (matches) tokens.push(t.token);
    }

    if (tokens.length === 0) return;

    const topicPrefix = data.clubTopic ? `[${data.clubTopic}] ` : '';
    const title = data.title || 'The Word Update';
    const body = `${topicPrefix}${data.message || ''}`.trim();

    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      await getMessaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data: {
          notificationId: snap.id,
          category: String(data.category || 'announcement'),
        },
      });
    }
  },
);
