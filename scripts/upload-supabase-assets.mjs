import { createHash } from 'node:crypto'
import { readdir, readFile } from 'node:fs/promises'
import { extname, join, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(fileURLToPath(new URL('..', import.meta.url)))
const imageDir = join(root, 'supabase', 'assets', 'upload')
const url = process.env.SUPABASE_URL?.replace(/\/$/, '')
const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY
const bucket = process.env.SUPABASE_STORAGE_BUCKET || 'club-media'
const maxBytes = 10 * 1024 * 1024

if (!url || !key) {
  throw new Error('Set SUPABASE_URL and SUPABASE_SECRET_KEY (or legacy SUPABASE_SERVICE_ROLE_KEY) before upload.')
}

const mime = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp', '.avif': 'image/avif' }

async function listImages(directory) {
  const entries = await readdir(directory, { withFileTypes: true })
  const nested = await Promise.all(entries.filter(entry => entry.isDirectory()).map(entry => listImages(join(directory, entry.name))))
  const files = entries.filter(entry => entry.isFile() && mime[extname(entry.name).toLowerCase()]).map(entry => join(directory, entry.name))
  return [...files, ...nested.flat()].sort()
}

const files = await listImages(imageDir)
if (!files.length) {
  console.log(`No images found in ${imageDir}. Add real club photos there, then rerun this command.`)
  process.exit(0)
}

for (const file of files) {
  const bytes = await readFile(file)
  if (bytes.byteLength > maxBytes) throw new Error(`${relative(imageDir, file)} exceeds the 10 MB bucket limit.`)

  const digest = createHash('sha256').update(bytes).digest('hex')
  const relativePath = relative(imageDir, file).split(sep).join('/')
  const path = `site/${relativePath}`
  const endpoint = `${url}/storage/v1/object/${encodeURIComponent(bucket)}/${path.split('/').map(encodeURIComponent).join('/')}`
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      apikey: key,
      'Content-Type': mime[extname(file).toLowerCase()],
      'x-upsert': 'true',
      'cache-control': '31536000',
    },
    body: bytes,
  })

  if (!response.ok) throw new Error(`${relativePath}: HTTP ${response.status} ${await response.text()}`)
  console.log(`${relativePath} -> ${bucket}/${path} (${bytes.length} bytes; sha256 ${digest.slice(0, 12)})`)
}
