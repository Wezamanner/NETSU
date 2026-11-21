import { parseStops } from '../utils/fleet.js'
import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'

export async function renderRoutes(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', role: 'status', hidden: true })
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let areaName = new Map()
  let query = ''

  const name = el('input', { required: true, maxlength: '80' })
  const area = el('select', { required: true })
  const description = el('textarea', { maxlength: '300' })
  const stops = el('textarea', { maxlength: '2000' })
  const submitBtn = el('button', { type: 'submit', text: t('saveRoute') })

  const form = el('form', { class: 'panel panel-pad' }, [
    el('h2', { text: t('routes') }),
    field(t('routeName'), name),
    field(t('area'), area),
    field(t('description'), description),
    field(t('stops'), stops),
    el('p', { class: 'muted', text: t('stopsHelp') }),
    submitBtn,
  ])

  const draw = () => {
    const filtered = allRows.filter((route) => {
      if (!query) return true
      return `${route.name} ${areaName.get(route.area_id) ?? ''}`.toLowerCase().includes(query)
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
    for (const route of filtered) {
      const stopCount = Array.isArray(route.stops) ? route.stops.length : 0
      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: route.name }),
        el('td', { text: areaName.get(route.area_id) ?? '' }),
        el('td', { class: 'mono', text: String(stopCount) }),
        el('td', {}, [
          badge(route.active ? t('active') : t('inactive'), route.active ? 'success' : 'neutral', route.active ? 'check' : 'xCircle'),
        ]),
        el('td', { class: 'cell-end' }, [
          el('button', {
            type: 'button',
            class: 'secondary btn-sm',
            text: route.active ? t('deactivate') : t('activate'),
            onclick: async () => {
              const { error: updateError } = await supabase
                .from('routes')
                .update({ active: !route.active })
                .eq('id', route.id)
              if (updateError) {
                show(error, t('routeFailed'))
                toast(t('routeFailed'), 'error')
              } else {
                toast(t('statusUpdated'), 'success')
                await load()
              }
            },
          }),
        ]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
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

  const load = async () => {
    tableHost.replaceChildren(skeletonTable(4))
    const { data, error: loadError } = await supabase
      .from('routes')
      .select('id, name, area_id, description, stops, active')
      .order('name')
    if (loadError) {
      show(error, t('setupBody'))
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    allRows = data ?? []
    draw()
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
      el('h1', { text: t('routes') }),
      el('p', { class: 'muted', text: t('stopsHelp') }),
    ]),
    status,
    error,
    el('div', { class: 'split' }, [form, listPanel]),
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
  areaName = new Map(areaRows.map((item) => [item.id, `${item.kebele_code} — ${item.name}`]))

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
    setBusy(submitBtn, true, t('saveRoute'))
    const { error: saveError } = await supabase.from('routes').insert({
      name: name.value.trim(),
      area_id: area.value,
      description: description.value.trim() || null,
      stops: parsed.stops,
    })
    setBusy(submitBtn, false, t('saveRoute'))
    if (saveError) {
      show(error, t('routeFailed'))
      toast(t('routeFailed'), 'error')
      return
    }
    name.value = ''
    description.value = ''
    stops.value = ''
    show(status, t('routeSaved'))
    toast(t('routeSaved'), 'success')
    await load()
  })
  await load()
}

function show(node, text) {
  node.hidden = false
  node.textContent = text
}

function hide(node) {
  node.hidden = true
  node.textContent = ''
}
