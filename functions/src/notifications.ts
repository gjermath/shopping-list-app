import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const onItemAdded = onDocumentCreated(
  "lists/{listId}/items/{itemId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const listId = event.params.listId;
    const addedBy = data.addedBy;

    const listDoc = await db.collection("lists").doc(listId).get();
    if (!listDoc.exists) return;

    const listData = listDoc.data()!;
    const memberIds = (listData.memberIds as string[]).filter((id) => id !== addedBy);

    if (memberIds.length === 0) return;

    const userDoc = await db.collection("users").doc(addedBy).get();
    const userName = userDoc.data()?.displayName || "Someone";

    const tokens: string[] = [];
    for (const memberId of memberIds) {
      const memberDoc = await db.collection("users").doc(memberId).get();
      const token = memberDoc.data()?.fcmToken;
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: listData.name,
        body: `${userName} added "${data.name || data.rawInput}"`,
      },
      data: {
        listId: listId,
        type: "item_added",
      },
    });
  }
);
