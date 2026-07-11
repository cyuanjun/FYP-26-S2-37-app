import { describe, it, expect, vi, beforeEach } from "vitest";
import { insertContactMessage } from "@/boundary/gateways/contactGateway";
import { submitContactMessage } from "@/controller/landing/submitContactMessage";

// (#) Fake the contact gateway so no row is really inserted.
vi.mock("@/boundary/gateways/contactGateway", () => ({
  insertContactMessage: vi.fn(async () => {}),
}));

const insertFake = vi.mocked(insertContactMessage);

beforeEach(() => insertFake.mockClear());

describe("submitContactMessage", () => {
  // (#) (+) Check if a complete message is trimmed and inserted.
  it("inserts a complete message", async () => {
    await submitContactMessage({
      submitter_name: "  Mia  ",
      submitter_email: "  mia@example.com ",
      message: "  Hello there  ",
    });
    expect(insertFake).toHaveBeenCalledWith({
      submitter_name: "Mia",
      submitter_email: "mia@example.com",
      message: "Hello there",
    });
  });

  // (#) (-) Check if a message with any blank field is rejected before insert.
  it("rejects a message missing a field", async () => {
    await expect(
      submitContactMessage({ submitter_name: "Mia", submitter_email: "mia@example.com", message: "   " }),
    ).rejects.toThrow(/complete all/i);
    expect(insertFake).not.toHaveBeenCalled();
  });
});
