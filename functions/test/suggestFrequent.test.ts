import { filterSuggestions } from "../src/suggestFrequent";

jest.mock("../src/gemini", () => ({
  getModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          suggestions: ["Milk", "Bread"],
        }),
      },
    }),
  }),
}));

describe("filterSuggestions", () => {
  it("filters frequent items using Gemini", async () => {
    const frequent = [
      { itemName: "Milk", purchaseCount: 10 },
      { itemName: "Eggs", purchaseCount: 8 },
      { itemName: "Bread", purchaseCount: 6 },
      { itemName: "Birthday Cake", purchaseCount: 1 },
    ];
    const currentItems = ["Eggs"];
    const result = await filterSuggestions(frequent, currentItems);
    expect(result).toContain("Milk");
    expect(result).toContain("Bread");
    expect(result).not.toContain("Eggs");
  });
});
