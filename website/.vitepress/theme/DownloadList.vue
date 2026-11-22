<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RELEASES, megabytes, releaseDate, useRelease, type Device } from './release'

const { release, failed, seen, processor, filesOf, recommended } = useRelease()

// The device the visitor picked to see files for. It starts on the device they are on, once that is known.
const chosen = ref<Device>('android')
watch(seen, (value) => {
  if (value !== 'other') chosen.value = value
}, { immediate: true })

const devices: { id: Device; label: string }[] = [
  { id: 'android', label: 'Android' },
  { id: 'tv', label: 'TV' },
  { id: 'ios', label: 'iPhone and iPad' },
  { id: 'windows', label: 'Windows' },
  { id: 'mac', label: 'Mac' },
  { id: 'linux', label: 'Linux' },
  { id: 'server', label: 'Sync server' },
]

const files = computed(() => filesOf())
const main = computed(() => recommended(chosen.value))
// The file offered on top is left out of the list under it. The two lists are made apart, so they are matched by name.
const rest = computed(() => files.value[chosen.value].filter((entry) => entry.asset.name !== main.value?.asset.name))
const deviceName = computed(() => devices.find((d) => d.id === chosen.value)?.label ?? '')
</script>

<template>
  <div class="downloads">
    <p v-if="failed" class="status">
      The list of files could not be loaded. You can still get them from
      <a :href="RELEASES" target="_blank" rel="noopener">the releases page</a>.
    </p>
    <p v-else-if="!release" class="status">Looking for the newest version…</p>
    <template v-else>
      <div class="picker" role="tablist" aria-label="Device">
        <button
          v-for="device in devices"
          :key="device.id"
          role="tab"
          :aria-selected="chosen === device.id"
          :class="{ active: chosen === device.id }"
          @click="chosen = device.id"
        >
          {{ device.label }}
          <span v-if="device.id === seen" class="you">Your device</span>
        </button>
      </div>

      <div v-if="main" class="hero">
        <div class="text">
          <span class="label">Download for {{ deviceName }}</span>
          <span class="note">{{ main.label }}<template v-if="main.note"> · {{ main.note }}</template></span>
          <span class="file">{{ main.asset.name }} · {{ megabytes(main.asset.size) }}</span>
        </div>
        <a class="button big" :href="main.asset.browser_download_url" download>Download</a>
      </div>
      <p v-if="main && chosen === 'android' && seen === 'android' && !processor" class="hint">
        Your browser did not say what processor the phone has, so this is the Universal file. It works everywhere.
      </p>

      <ul v-if="rest.length">
        <li v-for="entry in rest" :key="entry.asset.name">
          <div class="text">
            <span class="label">{{ entry.label }}</span>
            <span v-if="entry.note" class="note">{{ entry.note }}</span>
            <span class="file">{{ entry.asset.name }} · {{ megabytes(entry.asset.size) }}</span>
          </div>
          <a class="button" :href="entry.asset.browser_download_url" download>Download</a>
        </li>
      </ul>
      <p v-if="!files[chosen].length" class="status">There are no files for this device in the newest version.</p>

      <p class="version">
        Version <strong>{{ release.tag_name }}</strong> · {{ releaseDate(release.published_at) }} ·
        <a :href="release.html_url" target="_blank" rel="noopener">What is new</a> ·
        <a :href="RELEASES" target="_blank" rel="noopener">Older versions</a>
      </p>
    </template>
  </div>
</template>

<style scoped>
.downloads {
  margin-top: 24px;
}
.status,
.hint,
.version {
  color: var(--vp-c-text-2);
}
.hint {
  font-size: 14px;
}
.picker {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 16px 0;
}
.picker button {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 999px;
  border: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
  color: var(--vp-c-text-1);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.picker button.active {
  background: var(--vp-button-brand-bg);
  color: var(--vp-button-brand-text);
  border-color: transparent;
}
.you {
  font-size: 11px;
  font-weight: 600;
  padding: 1px 8px;
  border-radius: 999px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
}
.active .you {
  background: rgba(255, 255, 255, 0.2);
  color: inherit;
}
.hero,
li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 16px;
  background: var(--vp-c-bg-soft);
  margin: 0;
}
.hero {
  padding: 20px;
  border-color: var(--vp-c-brand-1);
  margin-bottom: 14px;
}
ul {
  list-style: none;
  margin: 0 0 16px;
  padding: 0;
  display: grid;
  gap: 10px;
}
.text {
  display: grid;
  gap: 2px;
  min-width: 0;
}
.label {
  font-weight: 600;
}
.hero .label {
  font-size: 18px;
}
.note {
  color: var(--vp-c-text-2);
  font-size: 14px;
}
.file {
  color: var(--vp-c-text-3);
  font-size: 12px;
  overflow-wrap: anywhere;
}
.button {
  flex: none;
  padding: 8px 18px;
  border-radius: 12px;
  font-weight: 600;
  text-decoration: none;
  background: var(--vp-button-brand-bg);
  color: var(--vp-button-brand-text);
}
.button.big {
  padding: 12px 28px;
}
.button:hover {
  background: var(--vp-button-brand-hover-bg);
}
@media (max-width: 520px) {
  .hero,
  li {
    flex-direction: column;
    align-items: stretch;
  }
  .button {
    text-align: center;
  }
}
/* On a phone the devices sit in one row that slides sideways, out to the edges of the screen. */
@media (max-width: 767px) {
  .picker {
    flex-wrap: nowrap;
    overflow-x: auto;
    margin-left: calc(50% - 50vw);
    margin-right: calc(50% - 50vw);
    padding: 0 calc(50vw - 50%) 4px;
    scrollbar-width: none;
  }
  .picker::-webkit-scrollbar {
    display: none;
  }
  .picker button {
    flex: none;
  }
}
</style>
