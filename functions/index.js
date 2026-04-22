const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ==================== NOTIFICACIÓN CUANDO SE CREA UN COMENTARIO ====================
exports.onNewComment = functions.firestore
  .document("blogs/{blogId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const blogId = context.params.blogId;

    try {
      // Obtener datos del blog
      const blogDoc = await admin.firestore()
        .collection("blogs")
        .doc(blogId)
        .get();

      if (!blogDoc.exists) return null;

      const blogData = blogDoc.data();
      const ownerId = blogData.userId;

      // No enviar notificación al propio autor del comentario
      if (ownerId === comment.userId) return null;

      // Obtener token FCM del dueño del post
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(ownerId)
        .get();

      const token = userDoc.data()?.fcmToken;

      if (!token) {
        console.log(`No FCM token for user: ${ownerId}`);
        return null;
      }

      const payload = {
        notification: {
          title: "Nuevo comentario",
          body: `${comment.userName || "Alguien"} comentó tu publicación`,
        },
        data: {
          type: "comment",
          blogId: blogId,
          // Puedes agregar más datos para navegar directamente al post
        }
      };

      // Método moderno recomendado
      await admin.messaging().send({
        token: token,
        ...payload
      });

      console.log(`Notificación enviada a ${ownerId}`);
    } catch (error) {
      console.error("Error enviando notificación de comentario:", error);
    }
  });

// ==================== NOTIFICACIÓN CUANDO SE CREA UNA RESPUESTA (REPLY) ====================
exports.onReply = functions.firestore
  .document("blogs/{blogId}/comments/{commentId}/replies/{replyId}")
  .onCreate(async (snap, context) => {
    const reply = snap.data();
    const { blogId, commentId } = context.params;

    try {
      // Obtener datos del comentario original
      const commentDoc = await admin.firestore()
        .collection("blogs")
        .doc(blogId)
        .collection("comments")
        .doc(commentId)
        .get();

      if (!commentDoc.exists) return null;

      const commentData = commentDoc.data();
      const ownerId = commentData.userId;

      // No enviar notificación al propio autor de la respuesta
      if (ownerId === reply.userId) return null;

      // Obtener token FCM del dueño del comentario
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(ownerId)
        .get();

      const token = userDoc.data()?.fcmToken;

      if (!token) {
        console.log(`No FCM token for user: ${ownerId}`);
        return null;
      }

      const payload = {
        notification: {
          title: "Nueva respuesta",
          body: `${reply.userName || "Alguien"} respondió a tu comentario`,
        },
        data: {
          type: "reply",
          blogId: blogId,
          commentId: commentId,
        }
      };

      await admin.messaging().send({
        token: token,
        ...payload
      });

      console.log(`Notificación de respuesta enviada a ${ownerId}`);
    } catch (error) {
      console.error("Error enviando notificación de respuesta:", error);
    }
  });