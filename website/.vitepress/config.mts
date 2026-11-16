import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitepress'

// The address the site is known by, put in the sitemap and in the links that say which page is the real one, so search engines list this one and not the web.app copy Firebase also serves.
const site = process.env.SITE_URL ?? 'https://sumizuri.notakari.com'

// What the app is, told to search engines on the home page.
const app = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'Sumizuri',
  url: `${site}/`,
  description: 'A media viewer for manga, comics, novels and anime. It comes with no content. You bring your own.',
  applicationCategory: 'MultimediaApplication',
  operatingSystem: 'Android, iOS, iPadOS, Windows, macOS, Linux',
  downloadUrl: `${site}/download`,
  image: `${site}/logo.png`,
  isAccessibleForFree: true,
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
}

// The packages are in the website folder, but the pages are in the docs folder beside it, where nothing can be found by looking up. So the pages are pointed at them.
const modules = fileURLToPath(new URL('../node_modules/', import.meta.url))

// The guides share one sidebar.
const guides = [
  {
    text: 'Guides',
    items: [
      { text: 'Overview', link: '/guides' },
      { text: 'Writing extensions', link: '/extensions' },
      { text: 'Profile block scripts', link: '/profile-blocks' },
      { text: 'Run a sync server', link: '/sync-server' },
    ],
  },
]

// The pages are the markdown files of the docs folder of the repo, so the guides there are the guides of the site and nothing is copied.
export default defineConfig({
  srcDir: '../docs',
  base: process.env.SITE_BASE ?? '/',
  title: 'Sumizuri',
  description: 'A media viewer for manga, comics, novels and anime, on Android, iPhone and iPad, and desktop.',
  cleanUrls: true,
  sitemap: { hostname: site },
  // Every page says which address is its own, so the same page under two addresses is counted once, and gives its own title and words to the previews that chats and search engines show.
  transformPageData(page) {
    const path = page.relativePath.replace(/(^|\/)index\.md$/, '$1').replace(/\.md$/, '')
    const home = path === ''
    const title = home ? `Sumizuri | ${page.frontmatter.titleTemplate}` : `${page.title} | Sumizuri`
    const description = page.description || page.frontmatter.description
    page.frontmatter.head ??= []
    page.frontmatter.head.push(['link', { rel: 'canonical', href: `${site}/${path}` }])
    page.frontmatter.head.push(['meta', { property: 'og:url', content: `${site}/${path}` }])
    page.frontmatter.head.push(['meta', { property: 'og:title', content: title }])
    page.frontmatter.head.push(['meta', { name: 'twitter:title', content: title }])
    if (description) {
      page.frontmatter.head.push(['meta', { property: 'og:description', content: description }])
      page.frontmatter.head.push(['meta', { name: 'twitter:description', content: description }])
    }
    if (home) page.frontmatter.head.push(['script', { type: 'application/ld+json' }, JSON.stringify(app)])
  },
  vite: {
    resolve: {
      alias: [{ find: /^vue(\/.*)?$/, replacement: `${modules}vue$1` }],
    },
  },
  lastUpdated: false,
  head: [
    ['link', { rel: 'icon', href: `${process.env.SITE_BASE ?? '/'}logo.png` }],
    ['meta', { name: 'theme-color', content: '#0f1114' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: 'Sumizuri' }],
    ['meta', { property: 'og:image', content: `${site}/logo.png` }],
    ['meta', { name: 'twitter:card', content: 'summary' }],
    // The code Google Search Console gives to prove the site is ours, when it is checked with a tag and not through DNS.
    ...(process.env.GOOGLE_SITE_VERIFICATION
      ? [['meta', { name: 'google-site-verification', content: process.env.GOOGLE_SITE_VERIFICATION }] as [string, Record<string, string>]]
      : []),
  ],
  themeConfig: {
    logo: '/logo.png',
    nav: [
      { text: 'Guides', link: '/guides', activeMatch: '^/(guides|extensions|profile-blocks|sync-server)' },
      { text: 'Download', link: '/download' },
      {
        text: 'About',
        items: [
          { text: 'Terms', link: '/terms' },
          { text: 'Privacy', link: '/privacy' },
          { text: 'Contact', link: '/contact' },
        ],
      },
    ],
    sidebar: {
      '/guides': guides,
      '/extensions': guides,
      '/profile-blocks': guides,
      '/sync-server': guides,
    },
    socialLinks: [
      { icon: 'discord', link: 'https://discord.gg/JZaqv5VFj7' },
      { icon: 'github', link: 'https://github.com/not-akari/sumizuri' },
    ],
    outline: { level: [2, 3], label: 'On this page' },
    docFooter: { prev: 'Previous', next: 'Next' },
    footer: {
      message: 'Sumizuri comes with no content. You bring your own, and you are responsible for it.<br><a href="/terms">Terms</a> · <a href="/privacy">Privacy</a> · <a href="/contact">Contact</a>',
    },
  },
})
