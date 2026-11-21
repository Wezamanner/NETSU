import { applyDocumentLocale, getLocale, setLocale, t } from '../i18n.js'
import { startRouter } from '../router.js'
import { isConfigured, supabase } from '../supabase-client.js'
import { el } from '../ui/dom.js'
import { officeGate } from '../utils/gate.js'

const root = document.querySelector('#app')
applyDocumentLocale()
const storedTheme = localStorage.getItem('netsu.theme')
document.documentElement.dataset.theme = storedTheme === 'dark' ? 'dark' : 'light'

if (!isConfigured() || !supabase) {
  root.append(panel(t('configTitle'), t('configBody')))
} else {
  const { data } = await supabase.auth.getSession()
  const session = data.session
  if (!session) {
    window.location.replace('./index.html')
  } else {
    const { data: role, error } = await supabase.rpc('auth_role')
    if (error) {
      root.append(panel(t('setupTitle'), t('setupBody')))
    } else if (officeGate({ signedIn: true, role }) !== 'app') {
      root.append(blocked())
    } else {
      const outlet = el('div')
      root.append(el('div', { class: 'shell' }, [
        el('aside', { class: 'nav' }, [
          el('a', { class: 'brand', href: '#/' }, [
            el('img', {
              class: 'logo',
              src: './assets/logo.jpg',
              alt: t('appTitle'),
            }),
          ]),
          navLink('', t('dashboard')),
          navLink('schedules', t('schedules')),
          navLink('reports', t('reports')),
          navLink('areas', t('areas')),
          navLink('routes', t('routes')),
          navLink('trucks', t('trucks')),
          navLink('workers', t('workers')),
          navLink('users', t('users')),
          navLink('feedback', t('feedback')),
          navLink('analytics', t('analytics')),
          el('button', {
            type: 'button',
            class: 'secondary',
            text: t('signOut'),
            onclick: async () => {
              await supabase.auth.signOut()
              window.location.replace('./index.html')
            },
          }),
        ]),
        el('main', { class: 'main' }, [
          el('div', { class: 'toolbar' }, [
            el('div', { class: 'lang', role: 'group', 'aria-label': t('language') }, [
              langButton('en', t('english')),
              langButton('am', t('amharic')),
              langButton('om', t('afaanOromo')),
            ]),
            el('button', {
              type: 'button',
              class: 'theme-toggle',
              text: document.documentElement.dataset.theme === 'dark' ? t('themeLight') : t('themeDark'),
              onclick: (event) => {
                const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'
                localStorage.setItem('netsu.theme', next)
                document.documentElement.dataset.theme = next
                event.currentTarget.textContent = next === 'dark' ? t('themeLight') : t('themeDark')
              },
            }),
          ]),
          outlet,
        ]),
      ]))
      await startRouter(outlet)
    }
  }
}

function navLink(id, label) {
  return el('a', { href: `#/${id}`, text: label })
}

function langButton(code, label) {
  return el('button', {
    type: 'button',
    text: label,
    'aria-pressed': getLocale() === code ? 'true' : 'false',
    onclick: () => {
      setLocale(code)
      window.location.reload()
    },
  })
}

function panel(title, body) {
  return el('main', { class: 'blocked' }, [
    el('section', { class: 'card auth-card' }, [
      el('h1', { text: title }),
      el('p', { text: body }),
      el('p', {}, [el('a', { href: './index.html', text: t('signIn') })]),
    ]),
  ])
}

function blocked() {
  return el('main', { class: 'blocked' }, [
    el('section', { class: 'card auth-card' }, [
      el('h1', { text: t('blockedTitle') }),
      el('p', { text: t('blockedBody') }),
      el('button', {
        type: 'button',
        text: t('signOut'),
        onclick: async () => {
          await supabase.auth.signOut()
          window.location.replace('./index.html')
        },
      }),
    ]),
  ])
}
