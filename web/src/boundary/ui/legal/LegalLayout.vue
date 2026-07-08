<script setup lang="ts">
import { RouterLink } from "vue-router";
import "./legal.css";

defineProps<{ title: string; updated: string }>();

const year = new Date().getFullYear();
</script>

<template>
  <main class="legal-shell">
    <div class="legal-inner">
      <div class="legal-top">
        <RouterLink to="/" class="legal-back">
          <span aria-hidden="true">←</span> Back to landing
        </RouterLink>
        <RouterLink to="/" class="legal-brand" aria-label="Wise Workout home">
          <span class="brand-mark" aria-hidden="true"></span>
          <span class="brand-name">Wise <span>Workout</span></span>
        </RouterLink>
      </div>

      <article class="legal-doc">
        <h1>{{ title }}</h1>
        <p class="legal-updated">Last updated {{ updated }}</p>
        <slot />
      </article>

      <p class="legal-footnote">
        © {{ year }} Wise Workout (FYP-26-S2-37). This is a student project; the text
        above is a standard template for demonstration and is not legal advice.
      </p>
    </div>
  </main>
</template>
