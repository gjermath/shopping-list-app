import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getModel, CATEGORIES, geminiApiKey } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface ParsedItem {
  name: string;
  quantity: string | null;
  category: string | null;
}

export async function parseRawInput(rawInput: string, language: string = "en"): Promise<ParsedItem[]> {
  const model = getModel();
  const languageName = language === "da" ? "Danish" : "English";

  const prompt = `Parse this shopping list input into individual items. The text is written in ${languageName}.
For each item, extract:
- name: the item name (clean, capitalized, in the original language)
- quantity: amount if mentioned (e.g., "2 lbs", "1 dozen"), or null
- category: one of [${CATEGORIES.join(", ")}] (always use English category names)

Input: "${rawInput}"

Respond with ONLY valid JSON: {"items": [{"name": "...", "quantity": "..." or null, "category": "..."}]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return [{ name: rawInput, quantity: null, category: null }];
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.items || [{ name: rawInput, quantity: null, category: null }];
  } catch {
    return [{ name: rawInput, quantity: null, category: null }];
  }
}

export const onItemCreated = onDocumentCreated(
  {
    document: "lists/{listId}/items/{itemId}",
    secrets: [geminiApiKey],
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const rawInput = data.rawInput;
    if (!rawInput) return;

    if (data.category) return;

    const listId = event.params.listId;
    const language = data.language || "en";

    try {
      const parsedItems = await parseRawInput(rawInput, language);

      if (parsedItems.length === 1) {
        const item = parsedItems[0];
        await snapshot.ref.update({
          name: item.name,
          quantity: item.quantity || null,
          category: item.category || "Other",
        });
      } else {
        const batch = db.batch();
        const itemsRef = db.collection("lists").doc(listId).collection("items");

        for (const item of parsedItems) {
          const newRef = itemsRef.doc();
          batch.set(newRef, {
            name: item.name,
            rawInput: rawInput,
            quantity: item.quantity || null,
            category: item.category || "Other",
            flagged: false,
            status: "active",
            addedBy: data.addedBy,
            addedAt: data.addedAt,
            source: data.source,
            language: language,
          });
        }

        batch.delete(snapshot.ref);
        await batch.commit();
      }
    } catch (error) {
      console.error("Parse failed, item will remain as-is:", error);
    }
  }
);
