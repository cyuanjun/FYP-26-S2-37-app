import { describe, it, expect, vi, beforeEach } from "vitest";
import { createExpertApplication } from "@/boundary/gateways/authGateway";
import { registerExpert } from "@/controller/auth/registerExpert";
import type { ExpertRegistrationForm } from "@/controller/auth/registrationModels";

// (#) Fake the gateway so no application is really submitted; validateBaseRegistration runs for real.
vi.mock("@/boundary/gateways/authGateway", () => ({
  createExpertApplication: vi.fn(async () => ({ id: "e1", role: "expert", status: "pending" })),
}));

const submitFake = vi.mocked(createExpertApplication);

// (#) A small in-memory File of a given mime type (size overridable for the limit test).
function fakeFile(name: string, type: string, size = 1024): File {
  const file = new File(["x"], name, { type });
  Object.defineProperty(file, "size", { value: size });
  return file;
}

// (#) A valid expert application the negative tests each break one field of.
function validForm(): ExpertRegistrationForm {
  return {
    first_name: "Sam",
    last_name: "Rivera",
    username: "sam_r",
    email: "sam@example.com",
    password: "Password123!",
    confirm: "Password123!",
    title: "Strength Coach",
    years_coaching: 5,
    about: "Certified strength coach with a decade of hands-on programming.",
    credentials: ["NSCA-CSCS"],
    specialties: ["strength"],
    identity_document: fakeFile("id.pdf", "application/pdf"),
    certification_documents: [fakeFile("cert.png", "image/png")],
  };
}

beforeEach(() => submitFake.mockClear());

describe("registerExpert", () => {
  // (#) (+) Check if a complete, valid application is submitted through the gateway.
  it("submits a valid application", async () => {
    const result = await registerExpert(validForm());
    expect(result.message).toMatch(/review/i);
    expect(submitFake).toHaveBeenCalledTimes(1);
  });

  // (#) (-) Check if a missing expert title is rejected.
  it("rejects a missing title", async () => {
    await expect(registerExpert({ ...validForm(), title: "  " })).rejects.toThrow(/title/i);
    expect(submitFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if a too-short "about" (under 30 chars) is rejected.
  it("rejects a too-short about", async () => {
    await expect(registerExpert({ ...validForm(), about: "too short" })).rejects.toThrow(/about/i);
    expect(submitFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if a missing identity document is rejected.
  it("rejects a missing identity document", async () => {
    await expect(registerExpert({ ...validForm(), identity_document: null })).rejects.toThrow(/identity/i);
    expect(submitFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if a disallowed document type (e.g. a .txt) is rejected.
  it("rejects a document of the wrong type", async () => {
    await expect(
      registerExpert({ ...validForm(), certification_documents: [fakeFile("cert.txt", "text/plain")] }),
    ).rejects.toThrow(/PDF, JPG, PNG/i);
    expect(submitFake).not.toHaveBeenCalled();
  });

  // (#) (-) Check if a document over the 5 MB limit is rejected.
  it("rejects a document over 5 MB", async () => {
    const big = fakeFile("cert.pdf", "application/pdf", 6 * 1024 * 1024);
    await expect(registerExpert({ ...validForm(), certification_documents: [big] })).rejects.toThrow(/5 MB/i);
    expect(submitFake).not.toHaveBeenCalled();
  });
});
