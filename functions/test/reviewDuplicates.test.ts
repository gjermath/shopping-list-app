import { findDuplicates } from "../src/reviewDuplicates";

jest.mock("../src/gemini", () => ({
  getModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          groups: [
            { items: ["Milk", "Whole milk", "2% milk"], suggestion: "Milk" },
          ],
        }),
      },
    }),
  }),
}));

describe("findDuplicates", () => {
  it("groups similar items", async () => {
    const items = ["Milk", "Whole milk", "2% milk", "Bread", "Eggs"];
    const result = await findDuplicates(items);
    expect(result).toHaveLength(1);
    expect(result[0].items).toContain("Milk");
    expect(result[0].items).toContain("Whole milk");
    expect(result[0].suggestion).toBe("Milk");
  });
});
