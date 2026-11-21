import { applyDocumentLocale, getLocale, setLocale, t } from '../i18n.js'
import { isConfigured, supabase } from '../supabase-client.js'
import { clear, el, field } from '../ui/dom.js'
import { normalizeEthiopianMobile, syntheticEmail } from '../utils/phone.js'

const root = document.querySelector('#app')
applyDocumentLocale()
applyTheme()

if (!isConfigured() || !supabase) {
  root.append(message(t('configTitle'), t('configBody')))
} else {
  const { data } = await supabase.auth.getSession()
  if (data.session) {
    const { data: role } = await supabase.rpc('auth_role')
    if (role === 'admin') window.location.replace('./app.html')
  }
  render()
}

function render() {
  clear(root)
  const error = el('p', { class: 'error', hidden: true })
  const success = el('p', { class: 'success', hidden: true })
  const phone = el('input', { type: 'tel', autocomplete: 'username', required: true })
  const password = el('input', { type: 'password', autocomplete: 'current-password', required: true, minlength: '8' })
  const name = el('input', { autocomplete: 'name', required: true, maxlength: '120' })
  const signInForm = el('form', {}, [
    field(t('phone'), phone),
    field(t('password'), password),
    el('button', { type: 'submit', text: t('signIn') }),
  ])
  signInForm.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(error)
    hide(success)
    const normalized = normalizeEthiopianMobile(phone.value)
    if (!normalized) return show(error, t('invalidPhone'))
    if (password.value.length < 8) return show(error, t('passwordShort'))
    const { error: authError } = await supabase.auth.signInWithPassword({
      email: syntheticEmail(normalized),
      password: password.value,
    })
    if (authError) return show(error, t('authFailed'))
    window.location.assign('./app.html')
  })

  const registerForm = el('form', {}, [
    field(t('fullName'), name),
    el('button', { type: 'submit', class: 'secondary', text: t('register') }),
  ])
  registerForm.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(error)
    hide(success)
    const normalized = normalizeEthiopianMobile(phone.value)
    if (!name.value.trim()) return show(error, t('fieldRequired'))
    if (!normalized) return show(error, t('invalidPhone'))
    if (password.value.length < 8) return show(error, t('passwordShort'))
    const { error: signUpError } = await supabase.auth.signUp({
      email: syntheticEmail(normalized),
      password: password.value,
      options: {
        data: {
          full_name: name.value.trim(),
          phone: normalized,
          preferred_language: getLocale(),
        },
      },
    })
    if (signUpError) return show(error, t('registerFailed'))
    await supabase.auth.signOut()
    show(success, t('registerNext'))
  })

  root.append(el('main', { class: 'auth-screen' }, [
    el('div', { class: 'auth-wrap' }, [
      controls(),
      el('section', { class: 'card auth-card' }, [
        el('div', { class: 'auth-brand' }, [
          el('h1', { class: 'brand-title' }, [
            el('img', {
              class: 'logo',
              src: './assets/logo.jpg',
              alt: t('appTitle'),
            }),
          ]),
          el('p', { class: 'muted subtitle', text: t('subtitle') }),
        ]),
        error,
        success,
        signInForm,
        el('details', { class: 'setup-box' }, [
          el('summary', { text: t('register') }),
          el('p', { class: 'muted', text: t('blockedBody') }),
          registerForm,
        ]),
      ]),
    ]),
  ]))
}

function controls() {
  const theme = el('button', {
    type: 'button',
    class: 'theme-toggle',
    text: document.documentElement.dataset.theme === 'dark' ? t('themeLight') : t('themeDark'),
    onclick: () => {
      const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'
      localStorage.setItem('netsu.theme', next)
      applyTheme()
      render()
    },
  })
  const languages = el('div', { class: 'lang', role: 'group', 'aria-label': t('language') }, [
    langButton('en', t('english')),
    langButton('am', t('amharic')),
    langButton('om', t('afaanOromo')),
  ])
  return el('div', { class: 'toolbar' }, [languages, theme])
}

function langButton(code, label) {
  return el('button', {
    type: 'button',
    text: label,
    'aria-pressed': getLocale() === code ? 'true' : 'false',
    onclick: () => {
      setLocale(code)
      render()
    },
  })
}

function applyTheme() {
  const stored = localStorage.getItem('netsu.theme')
  document.documentElement.dataset.theme = stored === 'dark' ? 'dark' : 'light'
}

function show(node, text) {
  node.hidden = false
  node.textContent = text
}

function hide(node) {
  node.hidden = true
  node.textContent = ''
}

function message(title, body) {
  return el('main', { class: 'blocked' }, [
    el('section', { class: 'card auth-card' }, [el('h1', { text: title }), el('p', { text: body })]),
  ])
}
