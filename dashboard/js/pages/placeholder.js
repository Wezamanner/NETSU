import { t } from '../i18n.js'
import { el } from '../ui/dom.js'

export function renderPlaceholder(outlet, titleKey) {
  outlet.append(
    el('header', { class: 'page-head' }, [el('h1', { text: t(titleKey) })]),
    el('section', { class: 'panel state' }, [
      el('h2', { text: t(titleKey) }),
      el('p', { text: t('comingSoon') }),
    ]),
  )
}
