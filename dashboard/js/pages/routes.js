import { parseStops } from '../utils/fleet.js'
import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { clear, el, field } from '../ui/dom.js'

export async function renderRoutes(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', hidden: true })
  const error = el('p', { class: 'error', hidden: true })
  const list = el('div', { class: 'table-wrap panel' })
  const name = el('input', { required: true, maxlength: '80' })
  const area = el('select', { required: true })
  const description = el('textarea', { maxlength: '300' })
  const stops = el('textarea', { maxlength: '2000' })
  const form = el('form', { class: 'panel', style: 'padding:16px' }, [
    el('h2', { text: t('routes') }),
    field(t('routeName'), name),
    field(t('area'), area),
    field(t('description'), description),
    field(t('stops'), stops),
    el('p', { class: 'muted', text: t('stopsHelp') }),
    el('button', { type: 'submit', text: t('saveRoute') }),
  ])
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('routes') }),
      el('p', { class: 'muted', text: t('stopsHelp') }),
    ]),
    status,
    error,
    el('div', { class: 'split' }, [form, list]),
  )

  const { data: areas, error: areaError } = await supabase
    .from('service_areas')
    .select('id, name, kebele_code, active')
    .order('kebele_code')
  if (areaError) {
    show(error, t('setupBody'))
    return
  }
  const areaRows = areas ?? []
  area.append(el('option', { value: '', text: t('selectArea') }))
  for (const item of areaRows) {
    area.append(el('option', { value: item.id, text: `${item.kebele_code} — ${item.name}` }))
  }
  const areaName = new Map(areaRows.map((item) => [item.id, `${item.kebele_code} — ${item.name}`]))

  form.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(status)
    hide(error)
    const parsed = parseStops(stops.value)
    if (!name.value.trim() || !area.value) {
      show(error, t('fieldRequired'))
      return
    }
    if (!parsed.ok) {
      show(error, t('invalidStops'))
      return
    }
    const { error: saveError } = await supabase.from('routes').insert({
      name: name.value.trim(),
      area_id: area.value,
      description: description.value.trim() || null,
      stops: parsed.stops,
    })
    if (saveError) {
      show(error, t('routeFailed'))
      return
    }
    name.value = ''
    description.value = ''
    stops.value = ''
    show(status, t('routeSaved'))
    await load(list, error, areaName)
  })
  await load(list, error, areaName)
}

async function load(list, error, areaName) {
  const { data, error: loadError } = await supabase
    .from('routes')
    .select('id, name, area_id, description, stops, active')
    .order('name')
  if (loadError) {
    show(error, t('setupBody'))
    return
  }
  const rows = data ?? []
  if (rows.length === 0) {
    list.replaceChildren(el('p', { class: 'state', text: t('empty') }))
    return
  }
  const body = el('tbody')
  for (const route of rows) {
    const stopCount = Array.isArray(route.stops) ? route.stops.length : 0
    body.append(el('tr', {}, [
      el('td', { text: route.name }),
      el('td', { text: areaName.get(route.area_id) ?? '' }),
      el('td', { text: String(stopCount) }),
      el('td', { text: route.active ? t('active') : t('inactive') }),
      el('td', {}, [
        el('button', {
          type: 'button',
          class: 'secondary',
          text: route.active ? t('deactivate') : t('activate'),
          onclick: async () => {
            const { error: updateError } = await supabase
              .from('routes')
              .update({ active: !route.active })
              .eq('id', route.id)
            if (updateError) show(error, t('routeFailed'))
            else await load(list, error, areaName)
          },
        }),
      ]),
    ]))
  }
  list.replaceChildren(el('table', {}, [
    el('thead', {}, [el('tr', {}, [
      el('th', { text: t('routeName') }),
      el('th', { text: t('area') }),
      el('th', { text: t('stops') }),
      el('th', { text: t('active') }),
      el('th', { text: '' }),
    ])]),
    body,
  ]))
}

function show(node, text) {
  node.hidden = false
  node.textContent = text
}

function hide(node) {
  node.hidden = true
  node.textContent = ''
}
