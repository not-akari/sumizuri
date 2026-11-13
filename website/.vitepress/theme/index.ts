import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import '@fontsource/inter/400.css'
import '@fontsource/inter/500.css'
import '@fontsource/inter/600.css'
import '@fontsource/inter/700.css'
import './custom.css'
import Cards from './Cards.vue'
import DownloadList from './DownloadList.vue'
import GuideCards from './GuideCards.vue'
import InstallSteps from './InstallSteps.vue'
import Landing from './Landing.vue'
import Layout from './Layout.vue'

// The default theme of VitePress with the look of the app laid over it, in custom.css, and the pieces the pages are built from.
export default {
  extends: DefaultTheme,
  Layout,
  enhanceApp({ app }) {
    app.component('Cards', Cards)
    app.component('DownloadList', DownloadList)
    app.component('GuideCards', GuideCards)
    app.component('InstallSteps', InstallSteps)
    app.component('Landing', Landing)
  },
} satisfies Theme
