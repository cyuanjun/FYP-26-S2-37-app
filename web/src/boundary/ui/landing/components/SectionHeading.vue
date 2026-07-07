<script setup lang="ts">
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
