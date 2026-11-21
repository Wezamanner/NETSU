import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { clear, el } from '../ui/dom.js'

export async function renderUsers(outlet) {
  clear(outlet)
  const error = el('p', { class: 'error', hidden: true })
  const list = el('div', { class: 'table-wrap panel' })
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('users') }),
      el('p', { class: 'muted', text: t('peopleHelp') }),
    ]),
    error,
    list,
  )
  const { data: sessionData } = await supabase.auth.getSession()
  const currentId = sessionData.session?.user.id
  const { data, error: loadError } = await supabase
    .from('profiles')
    .select('id, full_name, phone, role, active')
    .order('full_name')
  if (loadError) {
    error.hidden = false
    error.textContent = t('setupBody')
    return
  }
  const rows = data ?? []
  if (rows.length === 0) {
    list.append(el('p', { class: 'state', text: t('empty') }))
    return
  }
  const body = el('tbody')
  for (const person of rows) {
    const self = person.id === currentId
    body.append(el('tr', {}, [
      el('td', { text: self ? `${person.full_name} (${t('you')})` : person.full_name }),
      el('td', { text: person.phone }),
      el('td', { text: person.role }),
      el('td', { text: person.active ? t('active') : t('inactive') }),
      el('td', {}, [
        self
          ? ''
          : el('button', {
              type: 'button',
              class: 'secondary',
              text: person.active ? t('deactivate') : t('activate'),
              onclick: async () => {
                const { error: updateError } = await supabase
                  .from('profiles')
                  .update({ active: !person.active })
                  .eq('id', person.id)
                if (updateError) {
                  error.hidden = false
                  error.textContent = updateError.message
                  return
                }
                await renderUsers(outlet)
              },
            }),
      ]),
    ]))
  }
  list.append(el('table', {}, [
    el('thead', {}, [el('tr', {}, [
      el('th', { text: t('fullName') }),
      el('th', { text: t('phone') }),
      el('th', { text: t('role') }),
      el('th', { text: t('active') }),
      el('th', { text: '' }),
    ])]),
    body,
  ]))
}
