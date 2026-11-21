import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { clear, el } from '../ui/dom.js'

export async function renderWorkers(outlet) {
  clear(outlet)
  const error = el('p', { class: 'error', hidden: true })
  const list = el('div', { class: 'table-wrap panel' })
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('workers') }),
      el('p', { class: 'muted', text: t('workersHelp') }),
    ]),
    error,
    list,
  )
  const { data, error: loadError } = await supabase
    .from('profiles')
    .select('id, full_name, phone, active, area_id')
    .eq('role', 'worker')
    .order('full_name')
  if (loadError) {
    error.hidden = false
    error.textContent = t('setupBody')
    return
  }
  const { data: areas } = await supabase.from('service_areas').select('id, name, kebele_code')
  const areaName = new Map((areas ?? []).map((area) => [area.id, `${area.kebele_code} — ${area.name}`]))
  const rows = data ?? []
  if (rows.length === 0) {
    list.append(el('p', { class: 'state', text: t('empty') }))
    return
  }
  const body = el('tbody')
  for (const worker of rows) {
    body.append(el('tr', {}, [
      el('td', { text: worker.full_name }),
      el('td', { text: worker.phone }),
      el('td', { text: areaName.get(worker.area_id) ?? '' }),
      el('td', { text: worker.active ? t('active') : t('inactive') }),
    ]))
  }
  list.append(el('table', {}, [
    el('thead', {}, [el('tr', {}, [
      el('th', { text: t('fullName') }),
      el('th', { text: t('phone') }),
      el('th', { text: t('area') }),
      el('th', { text: t('active') }),
    ])]),
    body,
  ]))
}
