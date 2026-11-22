<script setup lang="ts">
import { withBase } from 'vitepress'

// A screenshot of the app in a phone: a metal rim with side buttons, a dark bezel and a small camera hole. The pictures are 720 by 1500.
withDefaults(defineProps<{ src: string; alt: string; eager?: boolean }>(), { eager: false })
</script>

<template>
  <div class="phone">
    <span class="key power" aria-hidden="true" />
    <span class="key volume" aria-hidden="true" />
    <div class="bezel">
      <img
        :src="withBase(src)"
        :alt="alt"
        width="720"
        height="1500"
        :loading="eager ? 'eager' : 'lazy'"
        decoding="async"
      />
      <span class="camera" aria-hidden="true" />
    </div>
  </div>
</template>

<style scoped>
/* The rim catches the light at its top left and bottom right corners, like brushed metal. */
.phone {
  position: relative;
  padding: 1.5px;
  border-radius: 23px;
  background: linear-gradient(150deg, #5b6069 0%, #23262b 22%, #15171a 50%, #23262b 78%, #4a4e56 100%);
  box-shadow:
    0 40px 70px -28px rgba(0, 0, 0, 0.6),
    0 12px 24px -12px rgba(0, 0, 0, 0.4);
}
.bezel {
  position: relative;
  padding: 3px;
  border-radius: 21.5px;
  background: #07080a;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.06);
}
img {
  display: block;
  width: 100%;
  height: auto;
  /* Small corners, so the screen of the app is not cut at its edges. */
  border-radius: 18.5px;
  background: #0f1114;
}
.camera {
  position: absolute;
  top: 8px;
  left: 50%;
  width: 8px;
  height: 8px;
  margin-left: -4px;
  border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #2a3140 0%, #050608 55%);
  box-shadow: 0 0 0 1.5px #000;
}
.key {
  position: absolute;
  width: 3px;
  border-radius: 2px;
  background: linear-gradient(90deg, #2b2e34, #4d525b);
}
.power {
  right: -2px;
  top: 24%;
  height: 11%;
}
.volume {
  left: -2px;
  top: 17%;
  height: 15%;
  background: linear-gradient(90deg, #4d525b, #2b2e34);
}
</style>
