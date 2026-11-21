import { t } from '../i18n.js'
import { mountMap, setMarkers } from '../map/osm.js'
import { supabase } from '../supabase-client.js'
import { badge, confirmDialog, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { el, field } from '../ui/dom.js'

export async function renderAreas(outlet) {
  const status = el('p', { class: 'success', role: 'status', hidden: true })
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let query = ''

  const name = el('input', { required: true, maxlength: '80' })
  const code = el('input', { required: true, maxlength: '16' })
  const description = el('textarea', { maxlength: '300' })
  const center = { lat: null, lng: null }
  const centerLabel = el('p', { class: 'muted coord-label', text: t('clickMap') })
  const mapHost = el('div', { class: 'osm-map osm-map-sm' })
  const submitBtn = el('button', { type: 'submit', text: t('saveArea') })

  const form = el('form', { class: 'panel panel-pad' }, [
    el('h2', { text: t('areas') }),
    field(t('areaName'), name),
    field(t('kebeleCode'), code),
    field(t('description'), description),
    centerLabel,
    mapHost,
    el('div', { class: 'form-actions' }, [submitBtn]),
  ])

  const draw = () => {
    const filtered = allRows.filter((area) => {
      if (!query) return true
      return `${area.kebele_code} ${area.name} ${area.description ?? ''}`.toLowerCase().includes(query)
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
    for (const area of filtered) {
      body.append(el('tr', {}, [
        el('td', { class: 'mono', text: area.kebele_code }),
        el('td', { class: 'strong-cell', text: area.name }),
        el('td', { class: 'muted', text: area.description ?? '' }),
        el('td', {}, [
          badge(area.active ? t('active') : t('inactive'), area.active ? 'success' : 'neutral', area.active ? 'check' : 'xCircle'),
        ]),
        el('td', { class: 'cell-end' }, [
          el('button', {
            type: 'button',
            class: 'secondary btn-sm',
            text: area.active ? t('deactivate') : t('activate'),
            onclick: async () => {
              if (area.active) {
                const ok = await confirmDialog({
                  title: t('confirmToggleTitle'),
                  body: t('confirmDeactivateBody'),
                  confirmLabel: t('deactivate'),
                })
                if (!ok) return
              }
              const { error: updateError } = await supabase
                .from('service_areas')
                .update({ active: !area.active })
                .eq('id', area.id)
              if (updateError) {
                show(error, t('areaFailed'))
                toast(t('areaFailed'), 'error')
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
        el('th', { text: t('kebeleCode') }),
        el('th', { text: t('areaName') }),
        el('th', { text: t('description') }),
        el('th', { text: t('active') }),
        el('th', { text: '' }),
      ])]),
      body,
    ]))
  }

  const load = async () => {
    tableHost.replaceChildren(skeletonTable(4))
    const { data, error: loadError } = await supabase
      .from('service_areas')
      .select('id, name, kebele_code, description, active, center_lat, center_lng')
      .order('kebele_code')
    if (loadError) {
      show(error, t('setupBody'))
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    allRows = data ?? []
    draw()
  }

  form.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(error)
    hide(status)
    if (!name.value.trim() || !code.value.trim()) {
      show(error, t('fieldRequired'))
      return
    }
    setBusy(submitBtn, true, t('saveArea'))
    const { error: saveError } = await supabase.from('service_areas').insert({
      name: name.value.trim(),
      kebele_code: code.value.trim(),
      description: description.value.trim() || null,
      center_lat: center.lat,
      center_lng: center.lng,
    })
    setBusy(submitBtn, false, t('saveArea'))
    if (saveError) {
      show(error, t('areaFailed'))
      toast(t('areaFailed'), 'error')
      return
    }
    name.value = ''
    code.value = ''
    description.value = ''
    center.lat = null
    center.lng = null
    centerLabel.textContent = t('clickMap')
    show(status, t('areaSaved'))
    toast(t('areaSaved'), 'success')
    await load()
  })

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
      el('h1', { text: t('areas') }),
      el('p', { class: 'muted', text: t('clickMap') }),
    ]),
    status,
    error,
    el('div', { class: 'split' }, [form, listPanel]),
  )

  mountMap(mapHost, {
    onClick(lat, lng) {
      center.lat = Number(lat.toFixed(6))
      center.lng = Number(lng.toFixed(6))
      centerLabel.textContent = `${center.lat}, ${center.lng}`
      setMarkers(mapHost, [{ lat: center.lat, lng: center.lng, label: name.value.trim() || t('areas') }])
    },
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
