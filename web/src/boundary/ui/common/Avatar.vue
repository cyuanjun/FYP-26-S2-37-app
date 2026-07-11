<script setup lang="ts">
// (#) Round avatar: shows the photo if given, otherwise falls back to the name's initials.
import { computed } from "vue";

// (#) name for the fallback initials, plus optional size and image.
const props = defineProps<{
  name: string;
  size?: number;
  imageUrl?: string;
}>();

// (#) Builds the initials from the first and last word of the name.
const initials = computed(() => {
  const parts = (props.name ?? "").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 1).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
});

// (#) The circle's width/height in px (defaults to 32).
const sizePx = computed(() => `${props.size ?? 32}px`);
// (#) Scales the initials font to the avatar size, with a small floor.
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
  border: 1px solid var(--accent);
  border-radius: 50%;
  overflow: hidden;
  color: var(--accent);
  background: rgba(123, 47, 247, 0.08);
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
