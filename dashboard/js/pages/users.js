import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, confirmDialog, searchInput, skeletonTable, toast } from '../ui/components.js'
import { clear, el } from '../ui/dom.js'

export async function renderUsers(outlet) {
  clear(outlet)
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let currentId = null
  let query = ''
  let roleFilter = 'all'

  const filterBar = el('div', { class: 'filter-pills', role: 'group', 'aria-label': t('role') })
  const roles = ['all', 'admin', 'worker', 'resident']
  const drawFilters = () => {
    filterBar.replaceChildren(...roles.map((r) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: r === 'all' ? t('allFilter') : r,
      'aria-pressed': roleFilter === r ? 'true' : 'false',
      onclick: () => {
        roleFilter = r
        drawFilters()
        draw()
      },
    })))
  }

  const draw = () => {
    const filtered = allRows.filter((person) => {
      if (roleFilter !== 'all' && person.role !== roleFilter) return false
      if (!query) return true
      return `${person.full_name} ${person.phone} ${person.role}`.toLowerCase().includes(query)
    })
    if (allRows.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    if (filtered.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('noMatches') }))
      return
    }
    const body = el('tbody')
    for (const person of filtered) {
      const self = person.id === currentId
      const roleTone = person.role === 'admin' ? 'info' : person.role === 'worker' ? 'warning' : 'neutral'
      const roleIcon = person.role === 'worker' ? 'workers' : 'users'
      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: self ? `${person.full_name} (${t('you')})` : person.full_name }),
        el('td', { class: 'mono', text: person.phone }),
        el('td', {}, [badge(person.role, roleTone, roleIcon)]),
        el('td', {}, [
          badge(person.active ? t('active') : t('inactive'), person.active ? 'success' : 'neutral', person.active ? 'check' : 'xCircle'),
        ]),
        el('td', { class: 'cell-end' }, [
          self
            ? ''
            : el('button', {
                type: 'button',
                class: 'secondary btn-sm',
                text: person.active ? t('deactivate') : t('activate'),
                onclick: async () => {
                  if (person.active) {
                    const ok = await confirmDialog({
                      title: t('confirmToggleTitle'),
                      body: t('confirmDeactivateBody'),
                      confirmLabel: t('deactivate'),
                    })
                    if (!ok) return
                  }
                  const { error: updateError } = await supabase
                    .from('profiles')
                    .update({ active: !person.active })
                    .eq('id', person.id)
                  if (updateError) {
                    error.hidden = false
                    error.textContent = updateError.message
                    toast(updateError.message, 'error')
                    return
                  }
                  toast(t('statusUpdated'), 'success')
                  await load()
                },
              }),
        ]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
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

  const load = async () => {
    tableHost.replaceChildren(skeletonTable(5))
    const { data: sessionData } = await supabase.auth.getSession()
    currentId = sessionData.session?.user.id ?? null
    const { data, error: loadError } = await supabase
      .from('profiles')
      .select('id, full_name, phone, role, active')
      .order('full_name')
    if (loadError) {
      error.hidden = false
      error.textContent = t('setupBody')
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    allRows = data ?? []
    draw()
  }

  drawFilters()
  const listPanel = el('section', { class: 'panel' }, [
    el('div', { class: 'list-toolbar' }, [
      searchInput({
        placeholder: t('searchPlaceholder'),
        onInput: (value) => {
          query = value
          draw()
        },
      }),
      filterBar,
    ]),
    tableHost,
  ])

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('users') }),
      el('p', { class: 'muted', text: t('peopleHelp') }),
    ]),
    error,
    listPanel,
  )
  await load()
}
