import { getLocale, setLocale, t } from '../i18n.js'
import { el } from './dom.js'
import { icon } from './icons.js'

const THEME_KEY = 'netsu.theme'

export function currentTheme() {
  return document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light'
}

export function applyStoredTheme() {
  try {
    const stored = localStorage.getItem(THEME_KEY)
    document.documentElement.dataset.theme = stored === 'dark' ? 'dark' : 'light'
  } catch {
    document.documentElement.dataset.theme = 'light'
  }
}

export function setTheme(next) {
  document.documentElement.dataset.theme = next === 'dark' ? 'dark' : 'light'
  try {
    localStorage.setItem(THEME_KEY, document.documentElement.dataset.theme)
  } catch {
    // Ignore storage errors in restricted browsing modes.
  }
}

/** Accessible 48x48 icon-only theme switcher (sun/moon) with smooth state swap. */
export function themeIconButton(onChange) {
  const btn = el('button', {
    type: 'button',
    class: 'icon-btn theme-icon-btn',
  })

  const sync = () => {
    const dark = currentTheme() === 'dark'
    const label = dark ? t('themeLight') : t('themeDark')
    btn.setAttribute('aria-label', label)
    btn.setAttribute('title', label)
    btn.setAttribute('aria-pressed', dark ? 'true' : 'false')
    btn.replaceChildren(
      el('span', { class: 'theme-icon-wrap' }, [icon(dark ? 'sun' : 'moon', 20)]),
    )
  }

  btn.addEventListener('click', () => {
    const next = currentTheme() === 'dark' ? 'light' : 'dark'
    setTheme(next)
    sync()
    btn.classList.remove('spin')
    void btn.offsetWidth
    btn.classList.add('spin')
    if (onChange) onChange(next)
  })

  sync()
  return btn
}

/** Accessible status badge combining icon + text (never color-only). */
export function badge(label, tone = 'neutral', iconName = 'check') {
  return el('span', { class: `badge badge-${tone}` }, [
    icon(iconName, 14),
    el('span', { text: label }),
  ])
}

export function scheduleBadge(status) {
  const map = {
    draft: ['neutral', 'clock'],
    published: ['info', 'schedules'],
    assigned: ['info', 'workers'],
    on_the_way: ['warning', 'trucks'],
    in_progress: ['info', 'clock'],
    completed: ['success', 'check'],
    delayed: ['warning', 'alert'],
    cancelled: ['danger', 'xCircle'],
  }
  const [tone, iconName] = map[status] ?? ['neutral', 'clock']
  return badge(t(`status_${status}`), tone, iconName)
}

/** Live search input with icon and instant clear button. */
export function searchInput({ placeholder, onInput }) {
  const input = el('input', {
    type: 'search',
    class: 'search-input',
    placeholder,
    'aria-label': placeholder,
  })
  const clearBtn = el('button', {
    type: 'button',
    class: 'icon-btn search-clear',
    hidden: true,
    'aria-label': t('clearSearch'),
    title: t('clearSearch'),
    onclick: () => {
      input.value = ''
      clearBtn.hidden = true
      onInput('')
      input.focus()
    },
  }, [icon('close', 16)])

  input.addEventListener('input', () => {
    clearBtn.hidden = input.value.length === 0
    onInput(input.value.trim().toLowerCase())
  })

  return el('div', { class: 'search-box' }, [
    el('span', { class: 'search-icon' }, [icon('search', 18)]),
    input,
    clearBtn,
  ])
}

/** Shimmer skeleton while data loads. */
export function skeletonTable(rows = 4) {
  const items = []
  for (let i = 0; i < rows; i += 1) {
    items.push(el('div', { class: 'skeleton-row' }, [
      el('span', { class: 'skeleton-bar w-25' }),
      el('span', { class: 'skeleton-bar w-40' }),
      el('span', { class: 'skeleton-bar w-20' }),
    ]))
  }
  return el('div', { class: 'skeleton-wrap', role: 'status', 'aria-label': t('loading') }, items)
}

/** Floating toast notification region. */
function toastRegion() {
  let region = document.querySelector('.toast-region')
  if (!region) {
    region = el('div', { class: 'toast-region', role: 'region', 'aria-live': 'polite', 'aria-atomic': 'true' })
    document.body.append(region)
  }
  return region
}

export function toast(message, tone = 'success') {
  const region = toastRegion()
  const iconName = tone === 'error' ? 'alert' : tone === 'warning' ? 'clock' : 'check'
  const item = el('div', { class: `toast toast-${tone}`, role: 'status' }, [
    icon(iconName, 18),
    el('span', { class: 'toast-text', text: message }),
    el('button', {
      type: 'button',
      class: 'icon-btn toast-close',
      'aria-label': t('close'),
      onclick: () => dismiss(),
    }, [icon('close', 16)]),
  ])

  let closed = false
  const dismiss = () => {
    if (closed) return
    closed = true
    item.classList.add('leaving')
    setTimeout(() => item.remove(), 180)
  }

  region.append(item)
  setTimeout(dismiss, 4200)
}

/** Accessible confirmation dialog using native <dialog>. */
export function confirmDialog({ title, body, confirmLabel, cancelLabel }) {
  return new Promise((resolve) => {
    const dialog = el('dialog', { class: 'modal' }, [
      el('div', { class: 'modal-head' }, [
        el('h2', { text: title }),
      ]),
      el('p', { class: 'muted', text: body }),
      el('div', { class: 'modal-actions' }, [
        el('button', {
          type: 'button',
          class: 'secondary',
          text: cancelLabel ?? t('cancel'),
          onclick: () => close(false),
        }),
        el('button', {
          type: 'button',
          text: confirmLabel ?? t('confirm'),
          onclick: () => close(true),
        }),
      ]),
    ])

    const close = (result) => {
      dialog.close()
      dialog.remove()
      resolve(result)
    }

    dialog.addEventListener('cancel', (event) => {
      event.preventDefault()
      close(false)
    })

    document.body.append(dialog)
    dialog.showModal()
  })
}

export function setBusy(button, busy, idleText) {
  button.disabled = busy
  button.classList.toggle('is-busy', busy)
  button.textContent = busy ? t('loading') : idleText
}

/** Accessible pill dropdown for selecting dashboard language (Amharic default). */
export function languageDropdown(onChange) {
  const current = getLocale()
  const options = [
    { code: 'am', label: 'አማርኛ' },
    { code: 'om', label: 'Afaan Oromoo' },
    { code: 'en', label: 'English' },
  ]
  const select = el('select', {
    class: 'lang-select',
    'aria-label': t('language'),
    title: t('language'),
    onchange: () => {
      setLocale(select.value)
      if (onChange) onChange(select.value)
    },
  }, options.map((opt) => el('option', {
    value: opt.code,
    text: opt.label,
    selected: opt.code === current,
  })))
  select.value = current

  return el('div', { class: 'lang-picker' }, [
    el('span', { class: 'lang-icon' }, [icon('globe', 18)]),
    select,
    el('span', { class: 'lang-chevron' }, [icon('chevronDown', 16)]),
  ])
}
