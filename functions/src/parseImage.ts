import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getVisionModel, CATEGORIES, geminiApiKey } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

interface ParsedItem {
  name: string;
  quantity: string | null;
  category: string | null;
}

export async function extractItemsFromImage(
  base64Image: string,
  mimeType: string
): Promise<ParsedItem[]> {
  const model = getVisionModel();

  const prompt = `Look at this image (recipe, shopping list, shelf, or handwritten note).
Extract every food/grocery item you can identify.
For each item, provide:
- name: clean item name
- quantity: amount if visible, or null
- category: one of [${CATEGORIES.join(", ")}]

Respond with ONLY valid JSON: {"items": [{"name": "...", "quantity": "..." or null, "category": "..."}]}`;

  const result = await model.generateContent([
    prompt,
    {
      inlineData: {
        data: base64Image,
        mimeType: mimeType,
      },
    },
  ]);

  const text = result.response.text();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return [];

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.items || [];
  } catch {
    return [];
  }
}

export const parseImage = onCall({ secrets: [geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { imageUrl } = request.data;
  if (!imageUrl) {
    throw new HttpsError("invalid-argument", "imageUrl is required");
  }

  const bucket = admin.storage().bucket();
  const file = bucket.file(imageUrl);
  const [buffer] = await file.download();
  const base64 = buffer.toString("base64");

  const [metadata] = await file.getMetadata();
  const mimeType = metadata.contentType || "image/jpeg";

  const items = await extractItemsFromImage(base64, mimeType);

  await file.delete().catch(() => {});

  return { items };
});
