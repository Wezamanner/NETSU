import { isValidPlate, normalizePlate, parseCapacity } from '../utils/fleet.js'
import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'

export async function renderTrucks(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', role: 'status', hidden: true })
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let query = ''

  const plate = el('input', { required: true, maxlength: '16', placeholder: 'OR-01-10001', autocomplete: 'off' })
  const capacity = el('input', { inputmode: 'decimal', maxlength: '8' })
  const availability = el('select', {}, [
    el('option', { value: 'available', text: t('available') }),
    el('option', { value: 'unavailable', text: t('unavailable') }),
  ])
  const maintenance = el('select', {}, [
    el('option', { value: 'ok', text: t('okStatus') }),
    el('option', { value: 'in_maintenance', text: t('inMaintenance') }),
  ])
  const submitBtn = el('button', { type: 'submit', text: t('saveTruck') })

  const form = el('form', { class: 'panel panel-pad' }, [
    el('h2', { text: t('trucks') }),
    field(t('plateNumber'), plate),
    field(t('capacity'), capacity),
    field(t('availability'), availability),
    field(t('maintenance'), maintenance),
    submitBtn,
  ])

  const draw = () => {
    const filtered = allRows.filter((truck) => {
      if (!query) return true
      return `${truck.plate_number} ${truck.availability} ${truck.maintenance}`.toLowerCase().includes(query)
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
    for (const truck of filtered) {
      const next = truck.maintenance === 'ok' ? 'in_maintenance' : 'ok'
      const availTone = truck.availability === 'available' ? 'success' : truck.availability === 'assigned' ? 'info' : 'neutral'
      body.append(el('tr', {}, [
        el('td', { class: 'mono strong-cell', text: truck.plate_number }),
        el('td', { text: truck.capacity ?? '—' }),
        el('td', {}, [badge(availabilityLabel(truck.availability), availTone, 'trucks')]),
        el('td', {}, [
          badge(
            truck.maintenance === 'ok' ? t('okStatus') : t('inMaintenance'),
            truck.maintenance === 'ok' ? 'success' : 'warning',
            truck.maintenance === 'ok' ? 'check' : 'wrench',
          ),
        ]),
        el('td', { class: 'cell-end' }, [
          el('button', {
            type: 'button',
            class: 'secondary btn-sm',
            text: next === 'ok' ? t('markOk') : t('markMaintenance'),
            onclick: async () => {
              const { error: updateError } = await supabase
                .from('trucks')
                .update({ maintenance: next })
                .eq('id', truck.id)
              if (updateError) {
                show(error, t('truckFailed'))
                toast(t('truckFailed'), 'error')
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
        el('th', { text: t('plateNumber') }),
        el('th', { text: t('capacity') }),
        el('th', { text: t('availability') }),
        el('th', { text: t('maintenance') }),
        el('th', { text: '' }),
      ])]),
      body,
    ]))
  }

  const load = async () => {
    tableHost.replaceChildren(skeletonTable(4))
    const { data, error: loadError } = await supabase
      .from('trucks')
      .select('id, plate_number, capacity, availability, maintenance')
      .order('plate_number')
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
    hide(status)
    hide(error)
    const plateNumber = normalizePlate(plate.value)
    const parsed = parseCapacity(capacity.value)
    if (!isValidPlate(plateNumber)) {
      show(error, t('invalidPlate'))
      return
    }
    if (!parsed.ok) {
      show(error, t('invalidCapacity'))
      return
    }
    setBusy(submitBtn, true, t('saveTruck'))
    const { error: saveError } = await supabase.from('trucks').insert({
      plate_number: plateNumber,
      capacity: parsed.capacity,
      availability: availability.value,
      maintenance: maintenance.value,
    })
    setBusy(submitBtn, false, t('saveTruck'))
    if (saveError) {
      show(error, t('truckFailed'))
      toast(t('truckFailed'), 'error')
      return
    }
    plate.value = ''
    capacity.value = ''
    show(status, t('truckSaved'))
    toast(t('truckSaved'), 'success')
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
      el('h1', { text: t('trucks') }),
      el('p', { class: 'muted', text: t('truckNote') }),
    ]),
    status,
    error,
    el('div', { class: 'split' }, [form, listPanel]),
  )
  await load()
}

function availabilityLabel(value) {
  if (value === 'assigned') return t('assignedStatus')
  if (value === 'unavailable') return t('unavailable')
  return t('available')
}

function show(node, text) {
  node.hidden = false
  node.textContent = text
}

function hide(node) {
  node.hidden = true
  node.textContent = ''
}
