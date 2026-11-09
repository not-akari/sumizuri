<script setup lang="ts">
import DefaultTheme from 'vitepress/theme'
import PageHead from './PageHead.vue'
</script>

<!-- The layout of VitePress, with the page head of the home page look put above the text of each inner page. -->
<template>
  <DefaultTheme.Layout>
    <template #doc-before>
      <PageHead />
    </template>
  </DefaultTheme.Layout>
</template>
