import { parseRawInput } from "../src/parseInput";

jest.mock("../src/gemini", () => ({
  getModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          items: [
            { name: "Chicken", quantity: "2 lbs", category: "Meat" },
            { name: "Rice", quantity: null, category: "Pantry" },
          ],
        }),
      },
    }),
  }),
  CATEGORIES: [
    "Produce", "Dairy", "Meat", "Bakery", "Frozen",
    "Beverages", "Snacks", "Pantry", "Household", "Personal Care", "Other",
  ],
}));

describe("parseRawInput", () => {
  it("parses multi-item natural language input", async () => {
    const result = await parseRawInput("2 lbs chicken and some rice");
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual({ name: "Chicken", quantity: "2 lbs", category: "Meat" });
    expect(result[1]).toEqual({ name: "Rice", quantity: null, category: "Pantry" });
  });
});
