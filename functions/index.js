const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');

initializeApp();
const db = getFirestore();

exports.onMessageCreated = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const messageRef = snapshot.ref;
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const chatRef = db.collection('chats').doc(chatId);

    // Transaction commune à l’écriture du statut lu : évite de ré-incrémenter
    // le badge si le destinataire ouvre le chat avant le traitement du trigger.
    const result = await db.runTransaction(async (transaction) => {
      const [chatSnapshot, latestMessageSnapshot] = await Promise.all([
        transaction.get(chatRef),
        transaction.get(messageRef),
      ]);
      if (!chatSnapshot.exists || !latestMessageSnapshot.exists) return null;
      const chat = chatSnapshot.data();
      const message = latestMessageSnapshot.data();
      const senderId = message.senderId;
      const participants = Array.isArray(chat.participants) ? chat.participants : [];
      const recipients = participants.filter((uid) => uid !== senderId);
      const preview = (message.text || '').trim() || '📷 Photo';
      const summary = {
        lastMessage: preview,
        lastMessageAt: message.createdAt || FieldValue.serverTimestamp(),
        lastMessageSenderId: senderId,
        lastMessageStatus: message.status || 'sent',
        lastMessageId: messageId,
      };
      if (message.status !== 'read') {
        for (const recipientId of recipients) {
          summary[`unreadCount.${recipientId}`] = FieldValue.increment(1);
        }
      }
      transaction.update(chatRef, summary);
      return {
        senderId,
        recipients,
        preview,
        status: message.status || 'sent',
        muted: chat.muted || {},
      };
    });
    if (!result || result.status === 'read') return;

    const notifyRecipients = result.recipients.filter((uid) => result.muted[uid] !== true);
    if (notifyRecipients.length === 0) return;
    const [senderSnapshot, recipientSnapshots] = await Promise.all([
      db.collection('users').doc(result.senderId).get(),
      Promise.all(notifyRecipients.map((uid) => db.collection('users').doc(uid).get())),
    ]);
    const senderName = senderSnapshot.exists ? senderSnapshot.data().name || 'Nouveau message' : 'Nouveau message';
    const tokenOwners = recipientSnapshots
      .map((doc) => ({ uid: doc.id, token: doc.exists ? doc.data().fcmToken : null }))
      .filter((entry) => typeof entry.token === 'string' && entry.token.length > 0);
    if (tokenOwners.length === 0) return;

    const unique = new Map();
    for (const entry of tokenOwners) unique.set(entry.token, entry.uid);
    const tokens = Array.from(unique.keys());
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: senderName,
        body: result.preview,
      },
      data: {
        chatId,
        messageId,
        senderId: result.senderId,
      },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });

    const staleTokens = [];
    response.responses.forEach((sendResult, index) => {
      if (!sendResult.success && [
        'messaging/registration-token-not-registered',
        'messaging/invalid-registration-token',
      ].includes(sendResult.error?.code)) {
        staleTokens.push(tokens[index]);
      }
    });
    if (staleTokens.length > 0) {
      const cleanup = db.batch();
      for (const entry of tokenOwners) {
        if (staleTokens.includes(entry.token)) {
          cleanup.update(db.collection('users').doc(entry.uid), { fcmToken: FieldValue.delete() });
        }
      }
      await cleanup.commit();
    }
    logger.info('Notification envoyée', { chatId, messageId, recipients: tokens.length });
  },
);

exports.onMessageStatusChanged = onDocumentUpdated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    const chatRef = db.collection('chats').doc(event.params.chatId);
    const chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) return;
    const chat = chatSnapshot.data();
    if (chat.lastMessageId !== event.params.messageId) return;
    await chatRef.update({ lastMessageStatus: after.status });
  },
);
