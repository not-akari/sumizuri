import { onMounted, ref } from 'vue'

// The public repo that holds the releases. The pages ask GitHub for the newest one and link straight to its files.
export const REPO = 'not-akari/sumizuri'
export const RELEASES = `https://github.com/${REPO}/releases`
const API = `https://api.github.com/repos/${REPO}/releases/latest`

// What a visitor sees is kept for a few minutes, since GitHub lets one address ask only a few dozen times an hour.
const KEEP_MS = 10 * 60 * 1000
const KEY = 'sumizuri-latest-release'

export interface Asset {
  name: string
  size: number
  browser_download_url: string
}
export interface Release {
  tag_name: string
  published_at: string
  html_url: string
  assets: Asset[]
}

export type Device = 'android' | 'tv' | 'ios' | 'windows' | 'mac' | 'linux' | 'server'
export type Seen = Device | 'other'

export interface Entry {
  asset: Asset
  label: string
  note?: string
  key?: string
}

export const abi: Record<string, { label: string; note: string }> = {
  universal: { label: 'Universal', note: 'Works on every phone. The biggest file.' },
  'arm64-v8a': { label: 'ARM 64-bit', note: 'Most phones from the last years.' },
  'armeabi-v7a': { label: 'ARM 32-bit', note: 'Older phones.' },
  x86_64: { label: 'x86 64-bit', note: 'Emulators and some tablets.' },
  x86: { label: 'x86 32-bit', note: 'Old emulators.' },
}
const abiOrder = Object.keys(abi)

// The same files of the app for TVs. Many TVs run 32-bit apps even with a 64-bit processor, so Universal is the safe pick.
const tvAbi: Record<string, { label: string; note: string }> = {
  universal: { label: 'Universal', note: 'Works on every TV. Take this one if you are not sure.' },
  'arm64-v8a': { label: 'ARM 64-bit', note: 'Newer TVs and boxes that run 64-bit apps.' },
  'armeabi-v7a': { label: 'ARM 32-bit', note: 'Most TVs and TV sticks.' },
  x86_64: { label: 'x86 64-bit', note: 'TV emulators.' },
  x86: { label: 'x86 32-bit', note: 'Old TV emulators.' },
}

// Shared by every component on the page, so the release is asked for once.
const release = ref<Release | null>(null)
const failed = ref(false)
const seen = ref<Seen>('other')
const processor = ref<string | null>(null)
let started = false

function detect(): Seen {
  const agent = navigator.userAgent
  // A TV browser says Android too, so it is asked first.
  if (/Android TV|Google ?TV|SMART-TV|BRAVIA|AFT[A-Z]/i.test(agent)) return 'tv'
  if (/Android/i.test(agent)) return 'android'
  if (/iPhone|iPad|iPod/i.test(agent)) return 'ios'
  if (/Windows/i.test(agent)) return 'windows'
  if (/Macintosh|Mac OS X/i.test(agent)) return 'mac'
  if (/Linux|X11|CrOS/i.test(agent)) return 'linux'
  return 'other'
}

// Chromium browsers can say the processor and its width when asked. The names are the ones of the Android files.
async function detectProcessor(): Promise<string | null> {
  try {
    const hints = await (navigator as any).userAgentData?.getHighEntropyValues(['architecture', 'bitness'])
    if (!hints) return null
    const bits = hints.bitness === '64' ? 64 : hints.bitness === '32' ? 32 : 0
    if (hints.architecture === 'arm') return bits === 64 ? 'arm64-v8a' : bits === 32 ? 'armeabi-v7a' : null
    if (hints.architecture === 'x86') return bits === 64 ? 'x86_64' : bits === 32 ? 'x86' : null
  } catch {}
  return null
}

async function load() {
  seen.value = detect()
  if (seen.value === 'android') processor.value = await detectProcessor()
  try {
    const kept = sessionStorage.getItem(KEY)
    if (kept) {
      const { at, data } = JSON.parse(kept)
      if (Date.now() - at < KEEP_MS) {
        release.value = data
        return
      }
    }
  } catch {}
  try {
    const answer = await fetch(API, { headers: { Accept: 'application/vnd.github+json' } })
    if (!answer.ok) throw new Error(String(answer.status))
    release.value = await answer.json()
    try {
      sessionStorage.setItem(KEY, JSON.stringify({ at: Date.now(), data: release.value }))
    } catch {}
  } catch {
    failed.value = true
  }
}

// The newest release, what kind of device the visitor has, and the files sorted by device. Starts loading once, in the browser.
export function useRelease() {
  onMounted(() => {
    if (started) return
    started = true
    load()
  })

  function filesOf(): Record<Device, Entry[]> {
    const out: Record<Device, Entry[]> = { android: [], tv: [], ios: [], windows: [], mac: [], linux: [], server: [] }
    for (const asset of release.value?.assets ?? []) {
      const name = asset.name
      const apk = name.match(/-([A-Za-z0-9_-]+)\.apk$/)
      // The files of the app for TVs have TV in their names, and would look like phone files by their ending alone.
      if (apk && name.includes('-TV-') && tvAbi[apk[1]]) out.tv.push({ asset, key: apk[1], label: tvAbi[apk[1]].label, note: tvAbi[apk[1]].note })
      else if (apk && abi[apk[1]]) out.android.push({ asset, key: apk[1], label: abi[apk[1]].label, note: abi[apk[1]].note })
      else if (name.endsWith('-setup.exe')) out.windows.push({ asset, label: 'Installer', note: 'Windows 64-bit.' })
      else if (name.endsWith('.ipa')) out.ios.push({ asset, label: 'App file (.ipa)', note: 'Not signed. Install it with AltStore or Sideloadly.' })
      else if (name.endsWith('.dmg')) out.mac.push({ asset, label: 'Disk image (.dmg)', note: 'Macs with Apple silicon. Intel Macs are not supported.' })
      else if (name.endsWith('.deb')) out.linux.push({ asset, label: '.deb package', note: 'Debian, Ubuntu and their relatives.' })
      else if (name.endsWith('.tar.gz')) out.linux.push({ asset, label: 'Archive (.tar.gz)', note: 'Any other Linux. Unpack it and run.' })
      else if (name.startsWith('sumizuri-sync')) out.server.push({ asset, label: name })
    }
    out.android.sort((a, b) => abiOrder.indexOf(a.key ?? '') - abiOrder.indexOf(b.key ?? ''))
    out.tv.sort((a, b) => abiOrder.indexOf(a.key ?? '') - abiOrder.indexOf(b.key ?? ''))
    return out
  }

  // The file to offer first for a device. On a phone it is the one for its processor when that is known, and the universal one when it is not.
  function recommended(device: Device): Entry | undefined {
    const list = filesOf()[device]
    if (device === 'android') return list.find((entry) => entry.key === processor.value) ?? list.find((entry) => entry.key === 'universal') ?? list[0]
    if (device === 'server') return undefined
    return list[0]
  }

  return { release, failed, seen, processor, filesOf, recommended }
}

export function megabytes(bytes: number): string {
  return `${(bytes / 1024 / 1024).toFixed(bytes > 100 * 1024 * 1024 ? 0 : 1)} MB`
}

export function releaseDate(value: string): string {
  return new Date(value).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })
}
