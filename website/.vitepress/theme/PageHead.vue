<script setup lang="ts">
import { useData } from 'vitepress'

// The top of an inner page in the look of the home page: the seal, a large title and one line about the page. A page gets it by setting lead in its frontmatter.
const { frontmatter } = useData()
</script>

<template>
  <header v-if="frontmatter.lead" class="page-head">
    <div class="wash" aria-hidden="true" />
    <p class="eyebrow"><span class="seal">墨</span> {{ frontmatter.eyebrow ?? 'Sumizuri' }}</p>
    <h1>{{ frontmatter.heading ?? frontmatter.title }}</h1>
    <p class="lead">{{ frontmatter.lead }}</p>
    <ul v-if="frontmatter.facts" class="facts">
      <li v-for="fact in frontmatter.facts" :key="fact">{{ fact }}</li>
    </ul>
  </header>
</template>

<style scoped>
.page-head {
  position: relative;
  margin: 0 0 40px;
  padding: 8px 0 32px;
  border-bottom: 1px solid var(--vp-c-divider);
}
.wash {
  position: absolute;
  top: -80px;
  right: -60px;
  width: 280px;
  height: 280px;
  border-radius: 50%;
  background: radial-gradient(circle at 45% 45%, var(--vp-c-brand-soft), transparent 68%);
  filter: blur(8px);
  pointer-events: none;
}
.eyebrow {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  margin: 0 0 18px;
  padding: 6px 14px 6px 6px;
  border-radius: 999px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 70%, transparent);
  font-size: 13px;
  font-weight: 600;
  color: var(--vp-c-text-2);
}
.seal {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: var(--vp-c-brand-1);
  color: var(--vp-c-bg);
  font-size: 14px;
  font-weight: 700;
}
h1 {
  position: relative;
  margin: 0;
  font-size: clamp(32px, 4.6vw, 46px);
  line-height: 1.08;
  letter-spacing: -0.03em;
  font-weight: 700;
}
.lead {
  position: relative;
  margin: 16px 0 0;
  max-width: 36em;
  font-size: 18px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}
.facts {
  position: relative;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 20px 0 0;
  padding: 0;
  list-style: none;
}
.facts li {
  padding: 5px 12px;
  border-radius: 999px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
  font-size: 13px;
  font-weight: 600;
}
</style>
