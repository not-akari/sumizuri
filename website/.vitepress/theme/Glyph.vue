<script setup lang="ts">
// Small line icons drawn here, so the site loads nothing from other companies. Each is a 24 by 24 drawing in the color of the text around it.
defineProps<{ name: string }>()

const paths: Record<string, string> = {
  pages: 'M4 5a1 1 0 0 1 1-1h6v16H5a1 1 0 0 1-1-1zM13 4h6a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-6zM7 8h2M7 11h2M15 8h2M15 11h2',
  book: 'M5 4h9a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h9M9 8h5',
  play: 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zM10 9v6l5-3z',
  folder: 'M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM8 13h8',
  tap: 'M9 11V6a2 2 0 0 1 4 0v5M13 10a2 2 0 0 1 4 0v4a6 6 0 0 1-6 6h-1a5 5 0 0 1-4-2l-2-3a2 2 0 0 1 3-2l2 2M5 4l1 1M17 4l-1 1M11 1v1',
  screen: 'M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM8 21h8M12 17v4M10 8v5l4-2.5z',
  shelf: 'M4 20h16M6 20V6h3v14M11 20V4h3v16M16.5 20l-1.5-12 3-.5 1.5 12',
  cloud: 'M7 18a4 4 0 0 1-.6-8A6 6 0 0 1 18 9a4.5 4.5 0 0 1-.5 9zM10 14l2-2 2 2M12 12v5',
  brush: 'M14 4l6 6-8 8a3 3 0 0 1-4 0 3 3 0 0 1 0-4zM8 14c-2 0-4 1.5-4 4 0 1 0 2-1 2 3 1 6 0 6-3',
  code: 'M8 8l-4 4 4 4M16 8l4 4-4 4M13.5 5l-3 14',
  android: 'M8 3h8a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2zM11 18h2',
  apple: 'M6 3h12a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2zM11 18h2',
  windows: 'M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM9 21h6M12 17v4',
  laptop: 'M5 5a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v10H5zM2 19h20l-2-4H4z',
  linux: 'M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM7 9l3 3-3 3M12 15h5',
  arrow: 'M5 12h14M13 6l6 6-6 6',
  chat: 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H10l-5 4v-4a2 2 0 0 1-1-2zM8 9h8M8 12h5',
  bug: 'M9 7a3 3 0 0 1 6 0M7 10h10v4a5 5 0 0 1-10 0zM12 10v9M4 13h3M17 13h3M5 19l2.5-2M19 19l-2.5-2M6 6l2 2M18 6l-2 2',
  shield: 'M12 3l8 3v6c0 4.5-3.4 8-8 9-4.6-1-8-4.5-8-9V6zM9 12l2 2 4-4',
  lock: 'M6 11h12v9H6zM8 11V8a4 4 0 0 1 8 0v3M12 15v2',
  hidden: 'M3 3l18 18M10.6 6.1A9 9 0 0 1 12 6c5 0 9 6 9 6a15 15 0 0 1-2.6 3.2M6.3 7.6C4.2 9.2 3 12 3 12s4 6 9 6a8.6 8.6 0 0 0 3.7-.8M9.9 9.9a3 3 0 0 0 4.2 4.2',
  globe: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z',
  server: 'M4 5h16v6H4zM4 13h16v6H4zM8 8h.01M8 16h.01M12 8h4M12 16h4',
  update: 'M20 12a8 8 0 1 1-2.3-5.7M20 4v5h-5',
  scale: 'M12 4v16M8 20h8M5 7h14M5 7l-3 7a3 3 0 0 0 6 0zM19 7l-3 7a3 3 0 0 0 6 0z',
  blocks: 'M4 4h7v7H4zM13 4h7v4h-7zM13 10h7v10h-7zM4 13h7v7H4z',
}
</script>

<template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.7"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <path :d="paths[name]" />
  </svg>
</template>
