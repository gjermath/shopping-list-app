import { GoogleGenerativeAI } from "@google/generative-ai";
import { defineSecret } from "firebase-functions/params";

export const geminiApiKey = defineSecret("GEMINI_API_KEY");

let genAI: GoogleGenerativeAI | null = null;

function getGenAI(): GoogleGenerativeAI {
  if (!genAI) {
    genAI = new GoogleGenerativeAI(geminiApiKey.value());
  }
  return genAI;
}

export function getModel() {
  return getGenAI().getGenerativeModel({ model: "gemini-2.0-flash" });
}

export function getVisionModel() {
  return getGenAI().getGenerativeModel({ model: "gemini-2.0-flash" });
}

export const CATEGORIES = [
  "Produce", "Dairy", "Meat", "Bakery", "Frozen",
  "Beverages", "Snacks", "Pantry", "Household", "Personal Care", "Other",
] as const;
