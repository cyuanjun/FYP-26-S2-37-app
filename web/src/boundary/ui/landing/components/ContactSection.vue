<script setup lang="ts">
import { reactive, ref, type Component } from "vue";
import { Facebook, Instagram, Youtube, Linkedin } from "lucide-vue-next";
import { submitContactMessage } from "@/controller/landing/submitContactMessage";
import type { ContactSectionData } from "@/controller/landing/viewModels";

defineProps<{ section: ContactSectionData }>();

const socialIcons: Record<string, Component> = {
  facebook: Facebook,
  instagram: Instagram,
  youtube: Youtube,
  linkedin: Linkedin,
};

function iconFor(name: string): Component | null {
  return socialIcons[name.toLowerCase()] ?? null;
}

const form = reactive({ name: "", email: "", message: "", agreed: false });
const status = ref<"idle" | "submitting" | "sent" | "error">("idle");
const errorMessage = ref<string | null>(null);

async function onSubmit() {
  errorMessage.value = null;
  if (!form.agreed) {
    errorMessage.value = "Please acknowledge the terms before sending.";
    status.value = "error";
    return;
  }
  status.value = "submitting";
  try {
    await submitContactMessage({
      submitter_name: form.name,
      submitter_email: form.email,
      message: form.message,
    });
    status.value = "sent";
    form.name = "";
    form.email = "";
    form.message = "";
    form.agreed = false;
  } catch (e) {
    errorMessage.value = e instanceof Error ? e.message : String(e);
    status.value = "error";
  }
}
</script>

<template>
  <section id="contact" class="section">
    <div class="section-inner contact-layout">
      <div class="contact-copy">
        <div class="eyebrow">{{ section.eyebrow }}</div>
        <h2 class="section-title">{{ section.contact_heading }}</h2>
        <h3>{{ section.contact_subheading }}</h3>
        <p>{{ section.contact_description }}</p>
        <div class="social-row">
          <span v-for="link in section.social_links" :key="link" :aria-label="link" :title="link">
            <component :is="iconFor(link)" v-if="iconFor(link)" :size="20" :stroke-width="2" aria-hidden="true" />
            <template v-else>{{ link }}</template>
          </span>
        </div>
      </div>
      <form class="contact-form" @submit.prevent="onSubmit">
        <input
          v-model="form.name"
          class="contact-field"
          type="text"
          placeholder="Your name"
          required
          minlength="1"
          maxlength="80"
        />
        <input
          v-model="form.email"
          class="contact-field"
          type="email"
          placeholder="Your email"
          required
        />
        <textarea
          v-model="form.message"
          class="contact-field contact-message"
          placeholder="Tell us how we can help"
          required
          minlength="10"
          maxlength="2000"
        ></textarea>
        <label class="contact-check">
          <input v-model="form.agreed" type="checkbox" />
          I agree to be contacted by the team.
        </label>
        <p v-if="status === 'sent'" class="contact-feedback success">
          Thanks — we got your message and will reply soon.
        </p>
        <p v-else-if="errorMessage" class="contact-feedback error">{{ errorMessage }}</p>
        <button
          class="button primary"
          type="submit"
          :disabled="status === 'submitting'"
        >
          {{ status === "submitting" ? "Sending…" : section.button_text }}
        </button>
      </form>
    </div>
  </section>
</template>

<style scoped>
.contact-feedback {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid var(--border);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.04em;
}
.contact-feedback.success {
  border-color: var(--lime);
  color: var(--lime);
  background: rgba(184, 255, 0, 0.06);
}
.contact-feedback.error {
  border-color: rgba(255, 45, 85, 0.5);
  color: #ff2d55;
  background: rgba(255, 45, 85, 0.06);
}
</style>
