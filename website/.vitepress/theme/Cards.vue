<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'
import Glyph from './Glyph.vue'

// A grid of cards in the look of the home page, filled from a list in the frontmatter of the page, so the words stay in the page and not in code.
const props = defineProps<{ from: string }>()
const { frontmatter } = useData()

type Card = { icon?: string; tag?: string; title: string; text: string; link?: string; action?: string }
const cards = computed<Card[]>(() => frontmatter.value[props.from] ?? [])

const outside = (link: string) => /^https?:/.test(link)
const href = (link: string) => (outside(link) ? link : withBase(link))
</script>

<template>
  <div class="cards vp-raw">
    <component
      :is="card.link ? 'a' : 'article'"
      v-for="card in cards"
      :key="card.title"
      class="card"
      :class="{ link: card.link }"
      :href="card.link ? href(card.link) : undefined"
      :target="card.link && outside(card.link) ? '_blank' : undefined"
      :rel="card.link && outside(card.link) ? 'noopener' : undefined"
    >
      <Glyph v-if="card.icon" :name="card.icon" class="glyph" />
      <span v-if="card.tag" class="tag">{{ card.tag }}</span>
      <span class="title">{{ card.title }}</span>
      <span class="text">{{ card.text }}</span>
      <span v-if="card.link" class="go">{{ card.action ?? 'Open' }} <Glyph name="arrow" class="arrow" /></span>
    </component>
  </div>
</template>

<style scoped>
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
  gap: 14px;
  margin: 24px 0 8px;
}
.card {
  display: grid;
  gap: 8px;
  align-content: start;
  padding: 22px;
  border-radius: 20px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 75%, transparent);
  backdrop-filter: blur(6px);
  text-decoration: none;
  color: var(--vp-c-text-1);
}
.card.link {
  transition: border-color 0.15s, transform 0.15s;
}
.card.link:hover {
  border-color: var(--vp-c-brand-1);
  transform: translateY(-2px);
}
.glyph {
  width: 38px;
  height: 38px;
  margin-bottom: 6px;
  padding: 8px;
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
  font-size: 17px;
  font-weight: 700;
  letter-spacing: -0.01em;
}
.text {
  font-size: 15px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}
.go {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-top: 6px;
  font-weight: 600;
  color: var(--vp-c-brand-1);
}
.arrow {
  width: 16px;
  height: 16px;
  transition: transform 0.15s;
}
.card.link:hover .arrow {
  transform: translateX(3px);
}
</style>
