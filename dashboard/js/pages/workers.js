import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, searchInput, skeletonTable } from '../ui/components.js'
import { clear, el } from '../ui/dom.js'

export async function renderWorkers(outlet) {
  clear(outlet)
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let areaName = new Map()
  let query = ''

  const draw = () => {
    const filtered = allRows.filter((worker) => {
      if (!query) return true
      return `${worker.full_name} ${worker.phone} ${areaName.get(worker.area_id) ?? ''}`.toLowerCase().includes(query)
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
    for (const worker of filtered) {
      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: worker.full_name }),
        el('td', { class: 'mono', text: worker.phone }),
        el('td', { text: areaName.get(worker.area_id) ?? '—' }),
        el('td', {}, [
          badge(worker.active ? t('active') : t('inactive'), worker.active ? 'success' : 'neutral', worker.active ? 'check' : 'xCircle'),
        ]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
      el('thead', {}, [el('tr', {}, [
        el('th', { text: t('fullName') }),
        el('th', { text: t('phone') }),
        el('th', { text: t('area') }),
        el('th', { text: t('active') }),
      ])]),
      body,
    ]))
  }

  const listPanel = el('section', { class: 'panel' }, [
    el('div', { class: 'list-toolbar' }, [
      searchInput({
        placeholder: t('searchPlaceholder'),
        onInput: (value) => {
          query = value
          draw()
        },
      }),
    ]),
    tableHost,
  ])

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('workers') }),
      el('p', { class: 'muted', text: t('workersHelp') }),
    ]),
    error,
    listPanel,
  )

  tableHost.replaceChildren(skeletonTable(4))
  const { data, error: loadError } = await supabase
    .from('profiles')
    .select('id, full_name, phone, active, area_id')
    .eq('role', 'worker')
    .order('full_name')
  if (loadError) {
    error.hidden = false
    error.textContent = t('setupBody')
    tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
    return
  }
  const { data: areas } = await supabase.from('service_areas').select('id, name, kebele_code')
  areaName = new Map((areas ?? []).map((area) => [area.id, `${area.kebele_code} — ${area.name}`]))
  allRows = data ?? []
  draw()
}
