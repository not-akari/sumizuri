<script setup lang="ts">
import { computed } from 'vue'
import { withBase } from 'vitepress'
import { releaseDate, useRelease, type Device } from './release'
import Glyph from './Glyph.vue'
import AppMock from './AppMock.vue'

const { release, seen, recommended } = useRelease()

// The button names the device the visitor is on when it is one with an app, and goes to the full list when it is not.
const names: Record<string, string> = { android: 'Android', windows: 'Windows', linux: 'Linux', mac: 'Mac', ios: 'iPhone' }
const device = computed<Device | null>(() => (seen.value in names ? (seen.value as Device) : null))
const direct = computed(() => (device.value ? recommended(device.value) : undefined))
const label = computed(() => (device.value && direct.value ? `Download for ${names[device.value]}` : 'Download'))
const href = computed(() => direct.value?.asset.browser_download_url ?? withBase('/download'))

const kinds = [
  { icon: 'pages', title: 'Manga and comics', text: 'Read page by page in the direction you like, or in one long scroll.' },
  { icon: 'book', title: 'Novels', text: 'Set the text the way you read best, and translate it into your language.' },
  { icon: 'play', title: 'Anime', text: 'Watch with subtitles, skip intros and credits, and save episodes for later.' },
  { icon: 'folder', title: 'Your own files', text: 'Open comics, PDF and EPUB books from your device.' },
]

// Three across on a wide screen: a wide tile and a small one, a small one and a wide one, then three small ones, so every row is full.
const features = [
  { icon: 'tap', title: 'Read your way', text: 'Four reading modes, two pages side by side, tap zones you set, auto scroll, and panel by panel reading for small screens.', wide: true },
  { icon: 'screen', title: 'A player that keeps up', text: 'Subtitles, speed, skip buttons, a small floating player, and the next server when a video does not start.' },
  { icon: 'shelf', title: 'A library that sorts itself', text: 'Shelves that fill by your rules, a release calendar, new chapter notices and reading stats.' },
  { icon: 'brush', title: 'Make it look like yours', text: 'Change every color, corner and backdrop in the theme editor, or start from a built in theme.', wide: true },
  { icon: 'cloud', title: 'Sync on your own server', text: 'Your library is locked on your device before it is sent, so the server cannot read it.' },
  { icon: 'code', title: 'Add the sources you trust', text: 'Install them from repos, or write your own in the app and test it as you go.' },
  { icon: 'folder', title: 'Profiles and backups', text: 'Give each person their own library, and keep everything in one backup file you can lock with a password.' },
]

const platforms = [
  { icon: 'android', name: 'Android' },
  { icon: 'apple', name: 'iPhone and iPad' },
  { icon: 'windows', name: 'Windows' },
  { icon: 'laptop', name: 'Mac' },
  { icon: 'linux', name: 'Linux' },
]
</script>

<template>
  <div class="landing">
    <section class="hero">
      <div class="copy">
        <p class="eyebrow"><span class="seal">墨</span> Free and open source</p>
        <h1>Everything you read and watch, in one quiet app.</h1>
        <p class="lead">Sumizuri is a media viewer for manga, comics, novels and anime. It comes with no content. You bring your own.</p>
        <div class="actions">
          <a class="button primary" :href="href">{{ label }}</a>
          <a class="button" :href="withBase('/download')">All downloads</a>
        </div>
        <p class="meta">
          <template v-if="release">Version {{ release.tag_name }} · {{ releaseDate(release.published_at) }}</template>
          <template v-else>&nbsp;</template>
        </p>
      </div>
      <AppMock class="mock" />
    </section>

    <section class="block">
      <h2>What you can read and watch</h2>
      <div class="kinds">
        <article v-for="kind in kinds" :key="kind.title" class="kind">
          <Glyph :name="kind.icon" class="glyph" />
          <h3>{{ kind.title }}</h3>
          <p>{{ kind.text }}</p>
        </article>
      </div>
    </section>

    <section class="block">
      <h2>Made to stay out of the way</h2>
      <p class="sub">The controls fade when you read. Everything else is one tap away, and almost all of it can be changed.</p>
      <div class="bento">
        <article v-for="feature in features" :key="feature.title" class="tile" :class="{ wide: feature.wide }">
          <Glyph :name="feature.icon" class="glyph" />
          <h3>{{ feature.title }}</h3>
          <p>{{ feature.text }}</p>
        </article>
      </div>
    </section>

    <section class="block quiet">
      <div class="promise">
        <h2>No account. No ads. No tracking.</h2>
        <p>Your library, history and settings stay on your device. Read what leaves it on the <a :href="withBase('/privacy')">privacy page</a>.</p>
      </div>
    </section>

    <section class="block">
      <h2>On every screen you use</h2>
      <div class="platforms">
        <a v-for="platform in platforms" :key="platform.name" class="platform" :href="withBase('/download')">
          <Glyph :name="platform.icon" class="glyph" />
          <span>{{ platform.name }}</span>
        </a>
      </div>
    </section>

    <section class="band">
      <div class="wash" aria-hidden="true" />
      <h2>Bring your own content</h2>
      <p class="sub">Sumizuri comes with no content. You choose what to add.</p>
      <div class="actions center">
        <a class="button primary" :href="href">{{ label }}</a>
        <a class="button" :href="withBase('/guides')">Read the guides</a>
      </div>
    </section>
  </div>
</template>

<style scoped>
.landing {
  max-width: 1160px;
  margin: 0 auto;
  padding: 0 24px 80px;
}

.hero {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr);
  align-items: center;
  gap: 48px;
  padding: 72px 0 64px;
}
.eyebrow {
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
  margin: 0;
  font-size: clamp(36px, 5.4vw, 60px);
  line-height: 1.05;
  letter-spacing: -0.03em;
  font-weight: 700;
  border: 0;
  padding: 0;
}
.lead {
  margin: 22px 0 0;
  max-width: 32em;
  font-size: 19px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}
.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 30px;
}
.actions.center {
  justify-content: center;
}
.button {
  display: inline-block;
  padding: 13px 24px;
  border-radius: 12px;
  font-weight: 600;
  text-decoration: none;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 80%, transparent);
  color: var(--vp-c-text-1);
  transition: background 0.15s, transform 0.15s;
}
.button:hover {
  background: var(--vp-button-alt-hover-bg);
  transform: translateY(-1px);
}
.button.primary {
  border-color: transparent;
  background: var(--vp-button-brand-bg);
  color: var(--vp-button-brand-text);
}
.button.primary:hover {
  background: var(--vp-button-brand-hover-bg);
}
.meta {
  margin: 16px 0 0;
  font-size: 14px;
  color: var(--vp-c-text-3);
}

.block {
  padding: 56px 0 0;
}
.block h2,
.band h2 {
  margin: 0 0 10px;
  font-size: clamp(26px, 3vw, 34px);
  letter-spacing: -0.02em;
  border: 0;
  padding: 0;
}
.sub {
  margin: 0;
  max-width: 40em;
  font-size: 17px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}

.glyph {
  width: 40px;
  height: 40px;
  padding: 9px;
  border-radius: 12px;
  color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-soft);
}
.kinds {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-top: 24px;
}
.kind,
.tile {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 24px;
  border-radius: 20px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 75%, transparent);
  backdrop-filter: blur(6px);
}
.kind h3,
.tile h3 {
  margin: 6px 0 0;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.01em;
}
.kind p,
.tile p {
  margin: 0;
  line-height: 1.65;
  color: var(--vp-c-text-2);
}

.bento {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin-top: 28px;
}
.tile.wide {
  grid-column: span 2;
}
.tile.wide p {
  max-width: 34em;
}

.quiet .promise {
  padding: 36px;
  border-radius: 24px;
  border: 1px dashed var(--vp-c-divider);
  text-align: center;
}
.promise p {
  margin: 0;
  color: var(--vp-c-text-2);
  line-height: 1.6;
}
.promise a {
  color: var(--vp-c-brand-1);
  text-underline-offset: 3px;
}

.platforms {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 12px;
  margin-top: 24px;
}
.platform {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 16px;
  border: 1px solid var(--vp-c-divider);
  background: color-mix(in srgb, var(--vp-c-bg-soft) 75%, transparent);
  font-weight: 600;
  text-decoration: none;
  color: var(--vp-c-text-1);
  transition: border-color 0.15s, transform 0.15s;
}
.platform:hover {
  border-color: var(--vp-c-brand-1);
  transform: translateY(-2px);
}
.platform .glyph {
  width: 34px;
  height: 34px;
  padding: 7px;
  flex: none;
}

.band {
  position: relative;
  overflow: hidden;
  margin-top: 72px;
  padding: 64px 24px;
  text-align: center;
  border-radius: 28px;
  border: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
}
.band .sub {
  margin: 0 auto;
}
.band h2,
.band .sub,
.band .actions {
  position: relative;
}
.wash {
  position: absolute;
  inset: -40%;
  background:
    radial-gradient(closest-side at 70% 30%, var(--vp-c-brand-soft), transparent),
    radial-gradient(closest-side at 25% 80%, color-mix(in srgb, var(--vp-c-text-1) 8%, transparent), transparent);
  filter: blur(20px);
}

@media (max-width: 1000px) {
  .kinds {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .bento {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .tile.wide {
    grid-column: auto;
  }
  .tile:last-child {
    grid-column: span 2;
  }
  .platforms {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 820px) {
  .hero {
    grid-template-columns: 1fr;
    padding: 40px 0 24px;
    gap: 36px;
  }
  .mock {
    max-width: 360px;
    margin: 0 auto;
  }
}

@media (max-width: 560px) {
  .kinds,
  .bento,
  .platforms {
    grid-template-columns: 1fr;
  }
  .tile.wide,
  .tile:last-child {
    grid-column: auto;
  }
  .quiet .promise {
    padding: 28px 20px;
  }
}
</style>
