import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getModel } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface FrequentItem {
  itemName: string;
  purchaseCount: number;
}

export async function filterSuggestions(
  frequent: FrequentItem[],
  currentItemNames: string[]
): Promise<string[]> {
  const currentSet = new Set(currentItemNames.map((n) => n.toLowerCase()));
  const candidates = frequent.filter(
    (f) => !currentSet.has(f.itemName.toLowerCase())
  );

  if (candidates.length === 0) return [];

  const model = getModel();

  const prompt = `Given these frequently purchased grocery items with purchase counts:
${candidates.map((c) => `- ${c.itemName} (bought ${c.purchaseCount} times)`).join("\n")}

Filter out items that seem like one-time or seasonal purchases (e.g., birthday cake, holiday items).
Return only items that are likely regular staples.

Respond with ONLY valid JSON: {"suggestions": ["item1", "item2", ...]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return candidates.map((c) => c.itemName);

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.suggestions || [];
  } catch {
    return candidates.map((c) => c.itemName);
  }
}

export const suggestFrequentItems = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { listId } = request.data;
  if (!listId) {
    throw new HttpsError("invalid-argument", "listId is required");
  }

  const historySnap = await db
    .collection("lists").doc(listId)
    .collection("history")
    .where("action", "==", "completed")
    .orderBy("purchaseCount", "desc")
    .limit(30)
    .get();

  const frequent: FrequentItem[] = historySnap.docs.map((doc) => ({
    itemName: doc.data().itemName,
    purchaseCount: doc.data().purchaseCount || 0,
  }));

  const deduped = new Map<string, FrequentItem>();
  for (const item of frequent) {
    const key = item.itemName.toLowerCase();
    const existing = deduped.get(key);
    if (!existing || existing.purchaseCount < item.purchaseCount) {
      deduped.set(key, item);
    }
  }

  const itemsSnap = await db
    .collection("lists").doc(listId)
    .collection("items")
    .where("status", "==", "active")
    .get();

  const currentNames = itemsSnap.docs.map((doc) => doc.data().name);

  const suggestions = await filterSuggestions(
    Array.from(deduped.values()),
    currentNames
  );

  return { suggestions };
});
