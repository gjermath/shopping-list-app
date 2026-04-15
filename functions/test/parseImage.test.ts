import { extractItemsFromImage } from "../src/parseImage";

jest.mock("../src/gemini", () => ({
  getVisionModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          items: [
            { name: "Flour", quantity: "2 cups", category: "Pantry" },
            { name: "Eggs", quantity: "3", category: "Dairy" },
            { name: "Butter", quantity: "1 stick", category: "Dairy" },
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

describe("extractItemsFromImage", () => {
  it("extracts items from a base64 image", async () => {
    const fakeBase64 = "iVBORw0KGgoAAAANS";
    const result = await extractItemsFromImage(fakeBase64, "image/jpeg");
    expect(result).toHaveLength(3);
    expect(result[0].name).toBe("Flour");
    expect(result[2].category).toBe("Dairy");
  });
});
