<script setup lang="ts">
// A drawing of the app in the colors of the site, with blank covers, so the page shows the look of Sumizuri and no one's content.
const covers = [
  ['#2e3170', '#9aa6c2'],
  ['#e8e0b0', '#c79a4a'],
  ['#3c414d', '#1a1d24'],
  ['#e7a3b6', '#6b6a80'],
  ['#6f8f55', '#2c303a'],
  ['#9aa6c2', '#343a4a'],
  ['#c79a4a', '#3c414d'],
  ['#4e5260', '#e8e0b0'],
  ['#1f2123', '#6f8f55'],
]
</script>

<template>
  <div class="scene" aria-hidden="true">
    <div class="moon" />
    <svg class="stroke" viewBox="0 0 400 400">
      <path d="M40 300 C 120 240, 180 330, 260 270 S 360 190, 380 120" />
    </svg>

    <div class="phone">
      <div class="status"><span /><span class="dots" /></div>
      <div class="top">
        <span class="title">Library</span>
        <span class="icons"><i /><i /></span>
      </div>
      <div class="chips"><b class="on" /><b /><b /><b /></div>
      <div class="grid">
        <div v-for="(cover, i) in covers" :key="i" class="cover" :style="{ background: `linear-gradient(160deg, ${cover[0]}, ${cover[1]})` }">
          <span v-if="i % 3 === 1" class="badge">{{ 3 + i }}</span>
          <span class="name" />
        </div>
      </div>
      <div class="dock"><i class="on" /><i /><i /><i /><i /></div>
    </div>

    <div class="card">
      <div class="thumb" />
      <div class="text">
        <span class="line wide" />
        <span class="line" />
        <span class="bar"><span /></span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.scene {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 460px;
}
.moon {
  position: absolute;
  top: 2%;
  right: 6%;
  width: 62%;
  aspect-ratio: 1;
  border-radius: 50%;
  background: radial-gradient(circle at 40% 40%, var(--vp-c-brand-soft), transparent 68%);
  filter: blur(6px);
}
.stroke {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.stroke path {
  fill: none;
  stroke: var(--vp-c-text-1);
  stroke-opacity: 0.06;
  stroke-width: 30;
  stroke-linecap: round;
  filter: blur(2px);
}

.phone {
  position: relative;
  width: 250px;
  padding: 14px 12px 12px;
  border-radius: 36px;
  border: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg);
  box-shadow:
    0 30px 60px -20px rgba(0, 0, 0, 0.45),
    0 0 0 6px color-mix(in srgb, var(--vp-c-bg-soft) 90%, transparent);
  transform: rotate(-3deg);
}
.status {
  display: flex;
  justify-content: space-between;
  padding: 0 8px 10px;
}
.status span {
  width: 26px;
  height: 6px;
  border-radius: 3px;
  background: var(--vp-c-text-3);
  opacity: 0.6;
}
.status .dots {
  width: 34px;
}
.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 6px;
}
.title {
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--vp-c-text-1);
}
.icons {
  display: flex;
  gap: 8px;
}
.icons i,
.dock i {
  display: block;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid var(--vp-c-text-2);
}
.chips {
  display: flex;
  gap: 6px;
  padding: 12px 6px 10px;
}
.chips b {
  width: 38px;
  height: 16px;
  border-radius: 8px;
  border: 1px solid var(--vp-c-divider);
}
.chips b.on {
  width: 30px;
  border: 0;
  background: var(--vp-c-brand-1);
}
.grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  padding: 0 4px;
}
.cover {
  position: relative;
  aspect-ratio: 2 / 3;
  border-radius: 10px;
  overflow: hidden;
}
.cover::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(transparent 55%, rgba(0, 0, 0, 0.45));
}
.name {
  position: absolute;
  left: 6px;
  right: 14px;
  bottom: 7px;
  height: 5px;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.8);
  z-index: 1;
}
.badge {
  position: absolute;
  top: 5px;
  right: 5px;
  z-index: 1;
  min-width: 18px;
  padding: 1px 5px;
  border-radius: 9px;
  font-size: 10px;
  font-weight: 700;
  text-align: center;
  background: var(--vp-c-brand-1);
  color: var(--vp-c-bg);
}
.dock {
  display: flex;
  justify-content: space-around;
  margin: 14px 18px 2px;
  padding: 10px 6px;
  border-radius: 999px;
  border: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
}
.dock i.on {
  border-color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-1);
}

.card {
  position: absolute;
  right: 2%;
  bottom: 12%;
  display: flex;
  gap: 12px;
  align-items: center;
  width: 210px;
  padding: 12px;
  border-radius: 18px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg) 88%, transparent);
  backdrop-filter: blur(10px);
  box-shadow: 0 18px 40px -16px rgba(0, 0, 0, 0.45);
  transform: rotate(2deg);
}
.thumb {
  flex: none;
  width: 42px;
  height: 58px;
  border-radius: 8px;
  background: linear-gradient(160deg, #2e3170, #e8e0b0);
}
.text {
  display: grid;
  gap: 7px;
  flex: 1;
}
.line {
  height: 7px;
  width: 60%;
  border-radius: 4px;
  background: var(--vp-c-text-3);
  opacity: 0.6;
}
.line.wide {
  width: 90%;
  background: var(--vp-c-text-1);
  opacity: 0.8;
}
.bar {
  height: 5px;
  border-radius: 3px;
  background: var(--vp-c-divider);
  overflow: hidden;
}
.bar span {
  display: block;
  width: 64%;
  height: 100%;
  background: var(--vp-c-brand-1);
}

@media (max-width: 820px) {
  .scene {
    min-height: 400px;
  }
  .card {
    right: 0;
  }
}
@media (max-width: 420px) {
  .phone {
    width: 220px;
  }
  .card {
    width: 180px;
  }
}
</style>
