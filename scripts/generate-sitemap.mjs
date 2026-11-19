import { readFile, writeFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const envFile = path.join(projectRoot, '.env.local')

try {
  const contents = await readFile(envFile, 'utf8')
  for (const line of contents.split(/\r?\n/)) {
    const match = line.match(/^\s*(VITE_[A-Z0-9_]+)\s*=\s*(.*?)\s*$/)
    if (match && !process.env[match[1]]) {
      process.env[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2')
    }
  }
} catch {
  // CI and Docker provide build variables through the process environment.
}

const siteUrl = (process.env.VITE_PUBLIC_SITE_URL || 'https://example.com').replace(/\/+$/, '')
const publicPaths = [
  '/',
  '/about',
  '/programs',
  '/trainers',
  '/pricing',
  '/schedule',
  '/contacts',
  '/faq',
]

async function getPublishedSlugs(table) {
  const supabaseUrl = process.env.VITE_SUPABASE_URL
  const publishableKey = process.env.VITE_SUPABASE_PUBLISHABLE_KEY
  if (!supabaseUrl || !publishableKey) return []

  const endpoint = new URL(`/rest/v1/${table}`, supabaseUrl)
  endpoint.searchParams.set('select', 'slug')
  endpoint.searchParams.set('is_published', 'eq.true')
  endpoint.searchParams.set('order', 'slug')

  const response = await fetch(endpoint, {
    headers: { apikey: publishableKey, Authorization: `Bearer ${publishableKey}` },
    signal: AbortSignal.timeout(8000),
  })
  if (!response.ok) throw new Error(`Supabase returned HTTP ${response.status}`)

  const records = await response.json()
  return records
    .map((record) => record.slug)
    .filter((slug) => typeof slug === 'string' && slug.length > 0)
    .map((slug) => `/${table === 'programs' ? 'programs' : 'trainers'}/${encodeURIComponent(slug)}`)
}

let dynamicPaths = []
try {
  const records = await Promise.all(['programs', 'trainers'].map(getPublishedSlugs))
  dynamicPaths = records.flat()
} catch {
  console.warn('Sitemap: Supabase content could not be loaded; generated the public route list only.')
}

const locations = [...new Set([...publicPaths, ...dynamicPaths])]
  .map((route) => `${siteUrl}${route}`)
  .sort((a, b) => a.localeCompare(b))
const xmlEscape = (value) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
const xml = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  ...locations.map((location) => `  <url><loc>${xmlEscape(location)}</loc></url>`),
  '</urlset>',
  '',
].join('\n')

await writeFile(path.join(projectRoot, 'public', 'sitemap.xml'), xml)
const robotsPath = path.join(projectRoot, 'public', 'robots.txt')
const robots = await readFile(robotsPath, 'utf8')
await writeFile(robotsPath, robots.replace(/^Sitemap: .*$/m, `Sitemap: ${siteUrl}/sitemap.xml`))
console.log(`Sitemap: wrote ${locations.length} public URLs using ${siteUrl}.`)
