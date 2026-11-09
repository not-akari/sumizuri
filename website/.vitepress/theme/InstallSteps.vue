<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRelease, type Device } from './release'

const { seen } = useRelease()

type Steps = { label: string; intro?: string; steps: string[]; after?: string }

// The steps of the README, kept short. The words are written here and are safe to show as they are.
const guides: Partial<Record<Device, Steps>> = {
  android: {
    label: 'Android',
    steps: [
      'Download the <strong>Universal</strong> file, or the one for your processor.',
      'Open it. Android asks you to allow installs from your browser or file manager. Allow it for this once.',
      'Press <strong>Install</strong>.',
    ],
  },
  ios: {
    label: 'iPhone and iPad',
    intro: 'The file is not signed, so a sideloading tool on your computer signs it with your own Apple ID. You need iOS 15 or newer and the cable of the phone. A free Apple ID makes an app that lasts 7 days, and the tool renews it on the same Wi-Fi.',
    steps: [
      'Install <a href="https://sideloadly.io" target="_blank" rel="noopener">Sideloadly</a> on your computer.',
      'On the phone, turn on <strong>Settings</strong>, <strong>Privacy &amp; Security</strong>, <strong>Developer Mode</strong>. The phone restarts.',
      'Connect the phone, drag the <code>.ipa</code> into Sideloadly, type your Apple ID and press <strong>Start</strong>.',
      'On the phone, open <strong>Settings</strong>, <strong>General</strong>, <strong>VPN &amp; Device Management</strong> and trust your Apple ID.',
    ],
    after: 'AltStore and Xcode work too. Their steps are in the <a href="https://github.com/not-akari/sumizuri#iphone-and-ipad" target="_blank" rel="noopener">README</a>.',
  },
  windows: {
    label: 'Windows',
    steps: [
      'Download the <code>-setup.exe</code> and run it.',
      'If Windows says <strong>Windows protected your PC</strong>, press <strong>More info</strong>, then <strong>Run anyway</strong>. The installer is not signed.',
      'Follow the setup. It installs for you only, so it needs no administrator.',
    ],
  },
  mac: {
    label: 'Mac',
    intro: 'For Macs with Apple silicon, such as the M1 and newer.',
    steps: [
      'Open the <code>.dmg</code> and drag <strong>Sumizuri</strong> onto <strong>Applications</strong>.',
      'The first time, open <strong>System Settings</strong>, <strong>Privacy &amp; Security</strong>, and press <strong>Open Anyway</strong> next to Sumizuri. Or run <code>xattr -cr /Applications/Sumizuri.app</code> once in the Terminal.',
      'For video, install mpv with <code>brew install mpv</code>.',
    ],
  },
  linux: {
    label: 'Linux',
    steps: [
      'On Debian and Ubuntu, run <code>sudo apt install ./Sumizuri-*-linux-amd64.deb</code>.',
      'On other Linux, unpack the <code>.tar.gz</code> and run <code>Sumizuri/bin/Sumizuri</code>.',
      'For video, install mpv, for example the <code>libmpv2</code> package.',
    ],
  },
}

const order: Device[] = ['android', 'ios', 'windows', 'mac', 'linux']
const chosen = ref<Device>('android')
watch(seen, (value) => {
  if (value in guides) chosen.value = value as Device
}, { immediate: true })
const guide = computed(() => guides[chosen.value]!)
</script>

<template>
  <div class="install vp-raw">
    <div class="picker" role="tablist" aria-label="Device">
      <button
        v-for="device in order"
        :key="device"
        role="tab"
        :aria-selected="chosen === device"
        :class="{ active: chosen === device }"
        @click="chosen = device"
      >
        {{ guides[device]!.label }}
      </button>
    </div>
    <div class="panel">
      <p v-if="guide.intro" class="intro">{{ guide.intro }}</p>
      <ol>
        <li v-for="(step, index) in guide.steps" :key="index">
          <span class="number">{{ index + 1 }}</span>
          <span v-html="step" />
        </li>
      </ol>
      <p v-if="guide.after" class="after" v-html="guide.after" />
    </div>
  </div>
</template>

<style scoped>
.install {
  margin: 20px 0 8px;
}
.picker {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 14px;
}
.picker button {
  padding: 8px 16px;
  border-radius: 999px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 70%, transparent);
  font-size: 14px;
  font-weight: 600;
  color: var(--vp-c-text-2);
  transition: background 0.15s, color 0.15s;
}
.picker button.active {
  border-color: transparent;
  background: var(--vp-button-brand-bg);
  color: var(--vp-button-brand-text);
}
.panel {
  padding: 24px;
  border-radius: 20px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 75%, transparent);
  backdrop-filter: blur(6px);
}
.intro,
.after {
  margin: 0 0 16px;
  line-height: 1.65;
  color: var(--vp-c-text-2);
}
.after {
  margin: 16px 0 0;
}
ol {
  display: grid;
  gap: 14px;
  margin: 0;
  padding: 0;
  list-style: none;
}
li {
  display: grid;
  grid-template-columns: 30px minmax(0, 1fr);
  gap: 12px;
  align-items: start;
  line-height: 1.65;
}
.number {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
  font-size: 13px;
  font-weight: 700;
}
.install :deep(code) {
  padding: 2px 6px;
  border-radius: 6px;
  background: var(--vp-code-bg);
  color: var(--vp-code-color);
  font-size: 0.88em;
  overflow-wrap: anywhere;
}
.install :deep(a) {
  color: var(--vp-c-brand-1);
  text-decoration: underline;
  text-underline-offset: 3px;
}
</style>
