import { describe, it, expect, vi, beforeEach } from "vitest";
import { resendVerificationEmail } from "@/boundary/gateways/authGateway";
import { resendVerification } from "@/controller/auth/resendVerification";

// (#) Fake the gateway so no verification email is really sent.
vi.mock("@/boundary/gateways/authGateway", () => ({
  resendVerificationEmail: vi.fn(async () => {}),
}));

const resendFake = vi.mocked(resendVerificationEmail);

beforeEach(() => resendFake.mockClear());

describe("resendVerification", () => {
  // (#) (+) Check if a valid email is normalised (trimmed + lower-cased) and passed to the gateway.
  it("resends to a normalised email", async () => {
    await resendVerification("  New@Example.com ");
    expect(resendFake).toHaveBeenCalledWith("new@example.com");
  });

  // (#) (-) Check if a blank email is rejected before the gateway is called.
  it("rejects a blank email", async () => {
    await expect(resendVerification("   ")).rejects.toThrow(/email/i);
    expect(resendFake).not.toHaveBeenCalled();
  });
});
