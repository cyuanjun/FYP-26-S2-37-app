<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{
  name: string;
  size?: number;
  imageUrl?: string;
}>();

const initials = computed(() => {
  const parts = (props.name ?? "").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 1).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
});

const sizePx = computed(() => `${props.size ?? 32}px`);
const fontPx = computed(() => `${Math.max(11, Math.round((props.size ?? 32) * 0.38))}px`);
</script>

<template>
  <div
    class="avatar"
    :style="{ width: sizePx, height: sizePx, fontSize: fontPx } as any"
    :aria-label="name"
  >
    <img v-if="imageUrl" :src="imageUrl" :alt="name" loading="lazy" decoding="async" />
    <span v-else>{{ initials }}</span>
  </div>
</template>

<style scoped>
.avatar {
  display: grid;
  flex-shrink: 0;
  place-items: center;
  border: 1px solid var(--lime);
  border-radius: 50%;
  overflow: hidden;
  color: var(--lime);
  background: rgba(184, 255, 0, 0.1);
  font-family: var(--display);
  font-weight: 800;
  letter-spacing: 0;
  line-height: 1;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
