import { cpSync, existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { basename, join, resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const srcDir = join(root, 'dashboard')
const outDir = join(root, 'dist')

rmSync(outDir, { recursive: true, force: true })
mkdirSync(outDir, { recursive: true })

const entries = ['index.html', 'app.html', 'assets', 'css', 'js']
for (const entry of entries) {
  const from = join(srcDir, entry)
  if (!existsSync(from)) continue
  cpSync(from, join(outDir, entry), {
    recursive: true,
    filter: (filePath) => {
      const name = basename(filePath)
      if (name.endsWith('.test.js')) return false
      if (name === 'config.js' || name === 'config.example.js') return false
      return true
    },
  })
}

const url = (process.env.SUPABASE_URL ?? '').trim()
const publishableKey = (process.env.SUPABASE_PUBLISHABLE_KEY ?? '').trim()

const configContents = `// Generated at build time by scripts/build-dashboard.mjs.
export const supabaseConfig = {
  url: ${JSON.stringify(url || 'https://YOUR_PROJECT_REF.supabase.co')},
  publishableKey: ${JSON.stringify(publishableKey || 'sb_publishable_xxx')},
}
`

writeFileSync(join(outDir, 'js', 'config.js'), configContents, 'utf8')

if (!url || !publishableKey) {
  console.warn(
    'Warning: SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY is not set. Set both in Vercel Project Settings -> Environment Variables.',
  )
} else {
  console.log('Built dashboard into dist/ with configured Supabase environment variables.')
}
