import { t } from '../i18n.js'
import { mountMap, setMarkers } from '../map/osm.js'
import { supabase } from '../supabase-client.js'
import { el, field } from '../ui/dom.js'

export async function renderAreas(outlet) {
  const status = el('p', { class: 'success', hidden: true })
  const error = el('p', { class: 'error', hidden: true })
  const list = el('div', { class: 'table-wrap panel' })
  const name = el('input', { required: true, maxlength: '80' })
  const code = el('input', { required: true, maxlength: '16' })
  const description = el('textarea', { maxlength: '300' })
  const center = { lat: null, lng: null }
  const centerLabel = el('p', { class: 'muted', text: t('clickMap') })
  const mapHost = el('div', { class: 'osm-map' })
  const form = el('form', { class: 'panel', style: 'padding:16px' }, [
    el('h2', { text: t('areas') }),
    field(t('areaName'), name),
    field(t('kebeleCode'), code),
    field(t('description'), description),
    centerLabel,
    mapHost,
    el('button', { type: 'submit', text: t('saveArea') }),
  ])
  form.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(error)
    hide(status)
    if (!name.value.trim() || !code.value.trim()) {
      show(error, t('fieldRequired'))
      return
    }
    const { error: saveError } = await supabase.from('service_areas').insert({
      name: name.value.trim(),
      kebele_code: code.value.trim(),
      description: description.value.trim() || null,
      center_lat: center.lat,
      center_lng: center.lng,
    })
    if (saveError) {
      show(error, t('areaFailed'))
      return
    }
    name.value = ''
    code.value = ''
    description.value = ''
    center.lat = null
    center.lng = null
    show(status, t('areaSaved'))
    await load(list, error)
  })

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('areas') }),
      el('p', { class: 'muted', text: t('clickMap') }),
    ]),
    status,
    error,
    el('div', { class: 'split' }, [form, list]),
  )
  mountMap(mapHost, {
    onClick(lat, lng) {
      center.lat = Number(lat.toFixed(6))
      center.lng = Number(lng.toFixed(6))
      centerLabel.textContent = `${center.lat}, ${center.lng}`
      setMarkers(mapHost, [{ lat: center.lat, lng: center.lng, label: name.value.trim() || t('areas') }])
    },
  })
  await load(list, error)
}

async function load(list, error) {
  const { data, error: loadError } = await supabase
    .from('service_areas')
    .select('id, name, kebele_code, description, active, center_lat, center_lng')
    .order('kebele_code')
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
  for (const area of rows) {
    body.append(el('tr', {}, [
      el('td', { text: area.kebele_code }),
      el('td', { text: area.name }),
      el('td', { text: area.description ?? '' }),
      el('td', { text: area.active ? t('active') : t('inactive') }),
      el('td', {}, [
        el('button', {
          type: 'button',
          class: 'secondary',
          text: area.active ? t('deactivate') : t('activate'),
          onclick: async () => {
            const { error: updateError } = await supabase
              .from('service_areas')
              .update({ active: !area.active })
              .eq('id', area.id)
            if (updateError) show(error, t('areaFailed'))
            else await load(list, error)
          },
        }),
      ]),
    ]))
  }
  list.replaceChildren(el('table', {}, [
    el('thead', {}, [el('tr', {}, [
      el('th', { text: t('kebeleCode') }),
      el('th', { text: t('areaName') }),
      el('th', { text: t('description') }),
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
