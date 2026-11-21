import { applyDocumentLocale, getLocale, t } from '../i18n.js'
import { isConfigured, supabase } from '../supabase-client.js'
import { applyStoredTheme, languageDropdown, setBusy, themeIconButton, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'
import { icon } from '../ui/icons.js'
import { normalizeEthiopianMobile, syntheticEmail } from '../utils/phone.js'

const root = document.querySelector('#app')
applyDocumentLocale()
applyStoredTheme()

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
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const success = el('p', { class: 'success', role: 'status', hidden: true })
  const phone = el('input', {
    type: 'tel',
    autocomplete: 'username',
    placeholder: '09XXXXXXXX',
    required: true,
  })
  const password = el('input', {
    type: 'password',
    autocomplete: 'current-password',
    required: true,
    minlength: '8',
  })
  const togglePass = el('button', {
    type: 'button',
    class: 'icon-btn input-action',
    'aria-label': t('showPassword'),
    title: t('showPassword'),
    'aria-pressed': 'false',
    onclick: () => {
      const showing = password.type === 'text'
      password.type = showing ? 'password' : 'text'
      const label = showing ? t('showPassword') : t('hidePassword')
      togglePass.setAttribute('aria-label', label)
      togglePass.setAttribute('title', label)
      togglePass.setAttribute('aria-pressed', showing ? 'false' : 'true')
      togglePass.replaceChildren(icon(showing ? 'eye' : 'eyeOff', 18))
    },
  }, [icon('eye', 18)])

  const passwordWrap = el('div', { class: 'input-wrap' }, [password, togglePass])
  const signInBtn = el('button', { type: 'submit', text: t('signIn') })
  const signInForm = el('form', {}, [
    field(t('phone'), phone),
    el('label', { class: 'field' }, [el('span', { text: t('password') }), passwordWrap]),
    signInBtn,
  ])

  signInForm.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(error)
    hide(success)
    const normalized = normalizeEthiopianMobile(phone.value)
    if (!normalized) return show(error, t('invalidPhone'))
    if (password.value.length < 8) return show(error, t('passwordShort'))
    setBusy(signInBtn, true, t('signIn'))
    const { error: authError } = await supabase.auth.signInWithPassword({
      email: syntheticEmail(normalized),
      password: password.value,
    })
    setBusy(signInBtn, false, t('signIn'))
    if (authError) return show(error, t('authFailed'))
    window.location.assign('./app.html')
  })

  const name = el('input', { autocomplete: 'name', required: true, maxlength: '120' })
  const registerBtn = el('button', { type: 'submit', class: 'secondary', text: t('register') })
  const registerForm = el('form', {}, [
    field(t('fullName'), name),
    registerBtn,
  ])
  registerForm.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(error)
    hide(success)
    const normalized = normalizeEthiopianMobile(phone.value)
    if (!name.value.trim()) return show(error, t('fieldRequired'))
    if (!normalized) return show(error, t('invalidPhone'))
    if (password.value.length < 8) return show(error, t('passwordShort'))
    setBusy(registerBtn, true, t('register'))
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
    setBusy(registerBtn, false, t('register'))
    if (signUpError) return show(error, t('registerFailed'))
    await supabase.auth.signOut()
    show(success, t('registerNext'))
    toast(t('registerNext'), 'success')
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
  return el('div', { class: 'toolbar' }, [
    languageDropdown(() => render()),
    themeIconButton(),
  ])
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
