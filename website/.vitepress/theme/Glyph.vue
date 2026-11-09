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
