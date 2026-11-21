import { applyDocumentLocale, t } from '../i18n.js'
import { startRouter } from '../router.js'
import { isConfigured, supabase } from '../supabase-client.js'
import { applyStoredTheme, languageDropdown, themeIconButton } from '../ui/components.js'
import { el } from '../ui/dom.js'
import { icon } from '../ui/icons.js'
import { officeGate } from '../utils/gate.js'

const root = document.querySelector('#app')
applyDocumentLocale()
applyStoredTheme()

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
      const outlet = el('div', { class: 'page-outlet' })
      const backdrop = el('div', { class: 'nav-backdrop', hidden: true })
      const sidebar = el('aside', { class: 'nav', 'aria-label': t('appTitle') }, [
        el('div', { class: 'nav-top' }, [
          el('a', { class: 'brand', href: '#/' }, [
            el('img', {
              class: 'logo',
              src: './assets/logo.jpg',
              alt: t('appTitle'),
            }),
          ]),
          el('button', {
            type: 'button',
            class: 'icon-btn nav-close',
            'aria-label': t('close'),
            onclick: () => setDrawer(false),
          }, [icon('close', 20)]),
        ]),
        el('nav', { class: 'nav-links' }, [
          navLink('', t('dashboard'), 'dashboard'),
          navLink('schedules', t('schedules'), 'schedules'),
          navLink('reports', t('reports'), 'reports'),
          navLink('areas', t('areas'), 'areas'),
          navLink('routes', t('routes'), 'routes'),
          navLink('trucks', t('trucks'), 'trucks'),
          navLink('workers', t('workers'), 'workers'),
          navLink('users', t('users'), 'users'),
          navLink('feedback', t('feedback'), 'feedback'),
          navLink('analytics', t('analytics'), 'analytics'),
        ]),
        el('button', {
          type: 'button',
          class: 'secondary sign-out-btn',
          onclick: async () => {
            await supabase.auth.signOut()
            window.location.replace('./index.html')
          },
        }, [icon('signOut', 18), el('span', { text: t('signOut') })]),
      ])

      const menuBtn = el('button', {
        type: 'button',
        class: 'icon-btn menu-btn',
        'aria-label': t('openMenu'),
        'aria-expanded': 'false',
        onclick: () => setDrawer(!sidebar.classList.contains('open')),
      }, [icon('menu', 20)])

      const setDrawer = (open) => {
        sidebar.classList.toggle('open', open)
        backdrop.hidden = !open
        menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false')
      }

      backdrop.addEventListener('click', () => setDrawer(false))
      sidebar.addEventListener('click', (event) => {
        if (event.target.closest('a')) setDrawer(false)
      })
      window.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && sidebar.classList.contains('open')) setDrawer(false)
      })

      root.append(el('div', { class: 'shell' }, [
        backdrop,
        sidebar,
        el('main', { class: 'main' }, [
          el('header', { class: 'topbar' }, [
            el('div', { class: 'topbar-left' }, [
              menuBtn,
              el('span', { class: 'topbar-sub muted', text: t('subtitle') }),
            ]),
            el('div', { class: 'topbar-right' }, [
              languageDropdown(() => window.location.reload()),
              themeIconButton(),
            ]),
          ]),
          outlet,
        ]),
      ]))
      await startRouter(outlet)
    }
  }
}

function navLink(id, label, iconName) {
  return el('a', { href: `#/${id}` }, [
    icon(iconName, 18),
    el('span', { text: label }),
  ])
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
