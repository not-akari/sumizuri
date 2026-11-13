<script setup lang="ts">
import PhoneShot from './PhoneShot.vue'
</script>

<template>
  <div class="scene">
    <div class="moon" aria-hidden="true" />
    <svg class="stroke" viewBox="0 0 400 400" aria-hidden="true">
      <path d="M40 300 C 120 240, 180 330, 260 270 S 360 190, 380 120" />
    </svg>
    <PhoneShot class="back" src="/screens/profile.jpg" alt="The profile page, with reading stats and the titles to go on with" />
    <PhoneShot class="front" src="/screens/library.jpg" alt="The library, a grid of covers with the floating bar at the bottom" eager />
  </div>
</template>

<style scoped>
.scene {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 520px;
}
.moon {
  position: absolute;
  top: 0;
  right: 4%;
  width: 66%;
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
.front,
.back {
  position: absolute;
  width: 230px;
}
.front {
  left: 14%;
  top: 4%;
  transform: rotate(-4deg);
  z-index: 1;
}
.back {
  right: 8%;
  top: 14%;
  width: 200px;
  transform: rotate(5deg);
  opacity: 0.85;
}

@media (max-width: 820px) {
  .scene {
    min-height: 470px;
  }
  .front {
    left: 8%;
    width: 210px;
  }
  .back {
    right: 4%;
    width: 180px;
  }
}
@media (max-width: 420px) {
  .scene {
    min-height: 420px;
  }
  .front {
    width: 185px;
    left: 4%;
  }
  .back {
    width: 160px;
    right: 0;
  }
}
</style>
