<script setup lang="ts">
import { withBase } from 'vitepress'
import Glyph from './Glyph.vue'

const guides = [
  { icon: 'code', title: 'Writing extensions', text: 'Connect Sumizuri to an API of your own.', href: '/extensions', tag: 'For developers' },
  { icon: 'pages', title: 'Profile block scripts', text: 'Make your own blocks for the profile page.', href: '/profile-blocks', tag: 'For tinkerers' },
  { icon: 'cloud', title: 'Run a sync server', text: 'Keep your library the same on every device.', href: '/sync-server', tag: 'For self-hosters' },
]
</script>

<template>
  <div class="cards">
    <a v-for="guide in guides" :key="guide.href" class="card" :href="withBase(guide.href)">
      <Glyph :name="guide.icon" class="glyph" />
      <span class="tag">{{ guide.tag }}</span>
      <span class="title">{{ guide.title }}</span>
      <span class="text">{{ guide.text }}</span>
      <span class="go">Read the guide <Glyph name="arrow" class="arrow" /></span>
    </a>
  </div>
</template>

<style scoped>
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
  margin-top: 28px;
}
.card {
  display: grid;
  gap: 8px;
  align-content: start;
  padding: 24px;
  border-radius: 20px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 75%, transparent);
  text-decoration: none;
  color: var(--vp-c-text-1);
  transition: border-color 0.15s, transform 0.15s;
}
.card:hover {
  border-color: var(--vp-c-brand-1);
  transform: translateY(-2px);
}
.glyph {
  width: 40px;
  height: 40px;
  margin-bottom: 8px;
  padding: 9px;
  border-radius: 12px;
  color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-soft);
}
.tag {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--vp-c-text-3);
}
.title {
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.01em;
}
.text {
  color: var(--vp-c-text-2);
  line-height: 1.6;
}
.go {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-top: 8px;
  font-weight: 600;
  color: var(--vp-c-brand-1);
}
.arrow {
  width: 16px;
  height: 16px;
  transition: transform 0.15s;
}
.card:hover .arrow {
  transform: translateX(3px);
}
</style>
