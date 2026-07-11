<script setup lang="ts">
// (#) Shared section heading: the small eyebrow label, the title and a
// (#) description line, reused across the landing sections.
// (#) the three bits of heading text to display
defineProps<{
  eyebrow: string;
  title: string;
  description: string;
}>();
</script>

<template>
  <div class="eyebrow">{{ eyebrow }}</div>
  <h2 class="section-title">{{ title }}</h2>
  <p class="section-description">{{ description }}</p>
</template>
