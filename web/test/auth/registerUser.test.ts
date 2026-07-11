import { describe, it, expect, vi, beforeEach } from "vitest";
import { createUserRegistration } from "@/boundary/gateways/authGateway";
import { registerUser, validateBaseRegistration } from "@/controller/auth/registerUser";
import type { UserRegistrationForm } from "@/controller/auth/registrationModels";

// (#) Replace the Supabase auth gateway with a fake so no account is really created.
vi.mock("@/boundary/gateways/authGateway", () => ({
  createUserRegistration: vi.fn(async () => ({ id: "u1", role: "free", status: "created" })),
}));

const createFake = vi.mocked(createUserRegistration);

// (#) A valid registration form the negative tests each break one field of.
function validForm(): UserRegistrationForm {
  return {
    first_name: "Mia",
    last_name: "Patel",
    username: "mia_p",
    email: "  Mia@Example.com ",
    password: "Password123!",
    confirm: "Password123!",
  };
}

beforeEach(() => createFake.mockClear());

describe("registerUser", () => {
  // (#) (+) Check if a valid form creates the account with a trimmed, lower-cased email.
  it("creates the account for a valid form", async () => {
    const result = await registerUser(validForm());
    expect(result.message).toContain("created");
    expect(createFake).toHaveBeenCalledTimes(1);
    expect(createFake.mock.calls[0][0].email).toBe("mia@example.com");
  });

  // (#) (-) Check if a blank name is rejected before the gateway is called.
  it("rejects a blank first or last name", async () => {
    await expect(registerUser({ ...validForm(), first_name: "  " })).rejects.toThrow(/name/i);
    expect(createFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if a username with illegal characters is rejected.
  it("rejects an invalid username", async () => {
    await expect(registerUser({ ...validForm(), username: "no spaces!" })).rejects.toThrow(/username/i);
    expect(createFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if a password under 8 characters is rejected.
  it("rejects a too-short password", async () => {
    await expect(registerUser({ ...validForm(), password: "short", confirm: "short" })).rejects.toThrow(/8 characters/i);
    expect(createFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if mismatched password + confirm is rejected.
  it("rejects when the passwords do not match", async () => {
    await expect(registerUser({ ...validForm(), confirm: "Different1!" })).rejects.toThrow(/do not match/i);
    expect(createFake).not.toHaveBeenCalled();
  });
});

describe("validateBaseRegistration", () => {
  // (#) (+) Check if a valid form passes validation without throwing.
  it("passes a valid form", () => {
    expect(() => validateBaseRegistration(validForm())).not.toThrow();
  });

  // (#) (-) Check if a two-character username is rejected (below the 3-char minimum).
  it("rejects a username that is too short", () => {
    expect(() => validateBaseRegistration({ ...validForm(), username: "ab" })).toThrow(/username/i);
  });
});
