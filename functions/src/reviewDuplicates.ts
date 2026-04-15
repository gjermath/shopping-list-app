import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getModel, geminiApiKey } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface DuplicateGroup {
  items: string[];
  suggestion: string;
}

export async function findDuplicates(itemNames: string[]): Promise<DuplicateGroup[]> {
  if (itemNames.length < 2) return [];

  const model = getModel();

  const prompt = `Review this shopping list for duplicates or very similar items:
${itemNames.map((n) => `- ${n}`).join("\n")}

Group any items that are duplicates or near-duplicates (e.g., "milk" and "whole milk", "chicken breast" and "chicken").
For each group, suggest a single name to keep.
Only group items that are genuinely similar — don't group unrelated items.
If no duplicates found, return empty groups.

Respond with ONLY valid JSON: {"groups": [{"items": ["item1", "item2"], "suggestion": "best name"}]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return [];

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.groups || [];
  } catch {
    return [];
  }
}

export const reviewDuplicates = onCall({ secrets: [geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { listId } = request.data;
  if (!listId) {
    throw new HttpsError("invalid-argument", "listId is required");
  }

  const itemsSnap = await db
    .collection("lists").doc(listId)
    .collection("items")
    .where("status", "==", "active")
    .get();

  const itemNames = itemsSnap.docs.map((doc) => doc.data().name as string);
  const groups = await findDuplicates(itemNames);

  return { groups };
});
