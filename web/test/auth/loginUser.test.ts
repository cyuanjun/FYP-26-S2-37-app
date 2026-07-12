import { describe, it, expect, vi, beforeEach } from "vitest";
import { loginUser, EmailNotConfirmedError } from "@/controller/auth/loginUser";

// (#) A controllable stand-in for the auth gateway. It's a plain function (not a
// (#) vi.fn) so Vitest doesn't track its result promise: loginUser catches a
// (#) rejection internally, and vi.fn's tracking would wrongly flag that as an error.
const gw = vi.hoisted(() => ({
  calls: 0,
  signOuts: 0,
  impl: (_input: unknown): Promise<unknown> => Promise.resolve(null),
}));

vi.mock("@/boundary/gateways/authGateway", () => ({
  EMAIL_NOT_CONFIRMED: "EMAIL_NOT_CONFIRMED",
  authenticateUser: (input: unknown) => {
    gw.calls += 1;
    return gw.impl(input);
  },
  signOutMember: async () => {
    gw.signOuts += 1;
  },
}));

// (#) Make the gateway resolve to a signed-in user of the given role/state.
function resolvesUser(overrides: Record<string, unknown> = {}) {
  gw.impl = async () => ({
    id: "u1",
    role: "free",
    status: "active",
    first_name: "Mia",
    expert_status: "none",
    ...overrides,
  });
}

// (#) Make the gateway reject the way authenticateUser does for that failure.
function rejectsWith(message: string) {
  gw.impl = async () => {
    throw new Error(message);
  };
}

beforeEach(() => {
  gw.calls = 0;
  gw.signOuts = 0;
  gw.impl = () => Promise.resolve(null);
});

describe("loginUser", () => {
  // (#) (+) Check if a free member is routed to the download page.
  it("routes a free member to /download", async () => {
    resolvesUser({ role: "free" });
    const result = await loginUser({ email: "free@x.com", password: "pw" });
    expect(result.redirectTo).toBe("/download");
  });

  // (#) (+) Check if an admin is routed to the admin portal.
  it("routes an admin to /admin", async () => {
    resolvesUser({ role: "admin" });
    const result = await loginUser({ email: "admin@x.com", password: "pw" });
    expect(result.redirectTo).toBe("/admin");
  });

  // (#) (+) Check if a pending applicant (still free role) is routed to the expert page.
  it("routes a pending expert applicant to /expert", async () => {
    resolvesUser({ role: "free", expert_status: "pending" });
    const result = await loginUser({ email: "noah@x.com", password: "pw" });
    expect(result.redirectTo).toBe("/expert");
  });

  // (#) (-) Check if a blank email is rejected before the gateway is called.
  it("rejects a blank email", async () => {
    await expect(loginUser({ email: "  ", password: "pw" })).rejects.toThrow(/email/i);
    expect(gw.calls).toBe(0);
  });

  // (#) (-) Check if a blank password is rejected before the gateway is called.
  it("rejects a blank password", async () => {
    await expect(loginUser({ email: "free@x.com", password: "" })).rejects.toThrow(/password/i);
    expect(gw.calls).toBe(0);
  });

  // (#) (-) Check if a suspended account is blocked AND its session is signed out.
  it("blocks a suspended account and signs it out", async () => {
    resolvesUser({ status: "suspended" });
    await expect(loginUser({ email: "free@x.com", password: "pw" })).rejects.toThrow(/suspended/i);
    expect(gw.signOuts).toBe(1);
  });

  // (#) (-) Check if an unverified email surfaces EmailNotConfirmedError carrying the email.
  it("raises EmailNotConfirmedError for an unverified email", async () => {
    rejectsWith("EMAIL_NOT_CONFIRMED");
    const err = await loginUser({ email: "New@X.com", password: "pw" }).catch((e) => e);
    expect(err).toBeInstanceOf(EmailNotConfirmedError);
    expect((err as EmailNotConfirmedError).email).toBe("new@x.com");
  });

  // (#) (-) Check if a genuine bad-credentials error is passed through unchanged.
  it("passes a bad-credentials error through", async () => {
    rejectsWith("Invalid email or password.");
    const err = await loginUser({ email: "free@x.com", password: "wrong" }).catch((e) => e);
    expect(err).not.toBeInstanceOf(EmailNotConfirmedError);
    expect((err as Error).message).toMatch(/invalid/i);
  });
});
