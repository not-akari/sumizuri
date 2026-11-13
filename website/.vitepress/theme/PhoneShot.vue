<script setup lang="ts">
import { withBase } from 'vitepress'

// A screenshot of the app in a thin phone frame. The pictures are 720 by 1500.
withDefaults(defineProps<{ src: string; alt: string; eager?: boolean }>(), { eager: false })
</script>

<template>
  <div class="phone">
    <img
      :src="withBase(src)"
      :alt="alt"
      width="720"
      height="1500"
      :loading="eager ? 'eager' : 'lazy'"
      decoding="async"
    />
  </div>
</template>

<style scoped>
.phone {
  padding: 7px;
  border-radius: 34px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 92%, transparent);
  box-shadow: 0 30px 60px -24px rgba(0, 0, 0, 0.5);
}
img {
  display: block;
  width: 100%;
  height: auto;
  border-radius: 28px;
  background: #0f1114;
}
</style>
