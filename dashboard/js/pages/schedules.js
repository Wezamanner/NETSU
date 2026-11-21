import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { clear, el, field } from '../ui/dom.js'
import { assignmentWarnings, blocksSave } from '../utils/schedule.js'
import { addisLocalToUtc, formatAddisDate, formatAddisTime } from '../utils/time.js'

export async function renderSchedules(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', hidden: true })
  const error = el('p', { class: 'error', hidden: true })
  const warning = el('p', { class: 'note', hidden: true })
  const list = el('div', { class: 'table-wrap panel' })
  const area = el('select', { required: true })
  const date = el('input', { type: 'date', required: true })
  const start = el('input', { type: 'time', required: true })
  const end = el('input', { type: 'time' })
  const route = el('select')
  const truck = el('select')
  const workers = el('select', { multiple: true, size: '5' })
  const form = el('form', { class: 'panel', style: 'padding:16px' }, [
    el('h2', { text: t('saveDraft') }),
    field(t('area'), area),
    field(t('collectionDate'), date),
    field(t('startTime'), start),
    field(t('endTime'), end),
    field(t('routes'), route),
    field(t('trucks'), truck),
    field(t('workers'), workers),
    warning,
    el('p', { class: 'muted', text: t('draftNote') }),
    el('button', { type: 'submit', text: t('saveDraft') }),
  ])
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('schedules') }),
      el('p', { class: 'muted', text: t('draftNote') }),
    ]),
    status,
    error,
    form,
    list,
  )

  const [areaResult, routeResult, truckResult, workerResult, scheduleResult, linkResult, sessionResult] =
    await Promise.all([
      supabase.from('service_areas').select('id, name, kebele_code').eq('active', true).order('kebele_code'),
      supabase.from('routes').select('id, name, area_id, active').eq('active', true).order('name'),
      supabase.from('trucks').select('id, plate_number, availability, maintenance').order('plate_number'),
      supabase.from('profiles').select('id, full_name, active').eq('role', 'worker').eq('active', true).order('full_name'),
      supabase.from('collection_schedules').select('id, area_id, collection_date, expected_start, expected_end, truck_id, status').order('collection_date', { ascending: false }),
      supabase.from('schedule_workers').select('schedule_id, worker_id'),
      supabase.auth.getSession(),
    ])
  if (areaResult.error || scheduleResult.error) {
    show(error, t('setupBody'))
    return
  }

  const areas = areaResult.data ?? []
  const routes = routeResult.data ?? []
  const trucks = truckResult.data ?? []
  const workerRows = workerResult.data ?? []
  const links = linkResult.data ?? []
  const schedules = (scheduleResult.data ?? []).map((item) => ({
    ...item,
    worker_ids: links.filter((link) => link.schedule_id === item.id).map((link) => link.worker_id),
  }))
  const areaName = new Map(areas.map((item) => [item.id, `${item.kebele_code} — ${item.name}`]))
  const userId = sessionResult.data.session?.user.id ?? null

  fillSelect(area, [{ value: '', text: t('selectArea') }, ...areas.map((item) => ({
    value: item.id,
    text: `${item.kebele_code} — ${item.name}`,
  }))])
  fillSelect(truck, [{ value: '', text: t('noTruck') }, ...trucks.map((item) => ({
    value: item.id,
    text: item.plate_number,
  }))])
  workers.replaceChildren()
  for (const person of workerRows) {
    workers.append(el('option', { value: person.id, text: person.full_name }))
  }

  const refreshRoutes = () => {
    const matching = routes.filter((item) => item.area_id === area.value)
    fillSelect(route, [{ value: '', text: t('noRoute') }, ...matching.map((item) => ({
      value: item.id,
      text: item.name,
    }))])
  }
  const refreshWarnings = () => {
    const startIso = addisLocalToUtc(date.value, start.value)
    const endIso = end.value ? addisLocalToUtc(date.value, end.value) : null
    if (!startIso) {
      hide(warning)
      return
    }
    const selectedTruck = trucks.find((item) => item.id === truck.value)
    const messages = assignmentWarnings({
      truck: selectedTruck,
      workerIds: selectedValues(workers),
      schedules,
      startIso,
      endIso,
    }).map(warningText)
    if (messages.length === 0) hide(warning)
    else show(warning, messages.join(' '))
  }
  area.addEventListener('change', () => {
    refreshRoutes()
  })
  for (const input of [date, start, end, truck, workers]) {
    input.addEventListener('change', refreshWarnings)
  }
  refreshRoutes()

  form.addEventListener('submit', async (event) => {
    event.preventDefault()
    hide(status)
    hide(error)
    if (!area.value || !date.value || !start.value) {
      show(error, t('fieldRequired'))
      return
    }
    const startIso = addisLocalToUtc(date.value, start.value)
    const endIso = end.value ? addisLocalToUtc(date.value, end.value) : null
    if (!startIso || (end.value && !endIso)) {
      show(error, t('pastTime'))
      return
    }
    if (new Date(startIso).getTime() <= Date.now()) {
      show(error, t('pastTime'))
      return
    }
    if (endIso && new Date(endIso).getTime() <= new Date(startIso).getTime()) {
      show(error, t('endBeforeStart'))
      return
    }
    const selectedTruck = trucks.find((item) => item.id === truck.value) ?? null
    const workerIds = selectedValues(workers)
    const warnings = assignmentWarnings({
      truck: selectedTruck,
      workerIds,
      schedules,
      startIso,
      endIso,
    })
    if (warnings.length) show(warning, warnings.map(warningText).join(' '))
    if (blocksSave(warnings)) {
      show(error, t('warnMaintenance'))
      return
    }
    const { data: created, error: saveError } = await supabase
      .from('collection_schedules')
      .insert({
        area_id: area.value,
        collection_date: date.value,
        expected_start: startIso,
        expected_end: endIso,
        route_id: route.value || null,
        truck_id: truck.value || null,
        created_by: userId,
        updated_by: userId,
      })
      .select('id')
      .single()
    if (saveError || !created) {
      show(error, t('scheduleFailed'))
      return
    }
    if (workerIds.length) {
      const { error: workerError } = await supabase.from('schedule_workers').insert(
        workerIds.map((workerId) => ({ schedule_id: created.id, worker_id: workerId })),
      )
      if (workerError) {
        await supabase.from('collection_schedules').delete().eq('id', created.id)
        show(error, t('scheduleFailed'))
        return
      }
    }
    const { error: historyError } = await supabase.from('schedule_history').insert({
      schedule_id: created.id,
      changed_by: userId,
      action: 'created',
      new: {
        status: 'draft',
        area_id: area.value,
        collection_date: date.value,
        expected_start: startIso,
        expected_end: endIso,
        route_id: route.value || null,
        truck_id: truck.value || null,
        worker_ids: workerIds,
      },
    })
    if (historyError) {
      await supabase.from('collection_schedules').delete().eq('id', created.id)
      show(error, t('scheduleFailed'))
      return
    }
    schedules.unshift({
      id: created.id,
      area_id: area.value,
      collection_date: date.value,
      expected_start: startIso,
      expected_end: endIso,
      truck_id: truck.value || null,
      status: 'draft',
      worker_ids: workerIds,
    })
    date.value = ''
    start.value = ''
    end.value = ''
    hide(warning)
    show(status, t('scheduleSaved'))
    drawList(list, schedules, areaName)
  })

  drawList(list, schedules, areaName)
}

function drawList(list, schedules, areaName) {
  if (schedules.length === 0) {
    list.replaceChildren(el('p', { class: 'state', text: t('empty') }))
    return
  }
  const body = el('tbody')
  for (const item of schedules) {
    const when = `${formatAddisDate(item.expected_start)} ${formatAddisTime(item.expected_start)}`
    body.append(el('tr', {}, [
      el('td', { text: areaName.get(item.area_id) ?? '' }),
      el('td', { text: when }),
      el('td', { text: t(`status_${item.status}`) }),
    ]))
  }
  list.replaceChildren(el('table', {}, [
    el('thead', {}, [el('tr', {}, [
      el('th', { text: t('area') }),
      el('th', { text: t('expected') }),
      el('th', { text: t('status') }),
    ])]),
    body,
  ]))
}

function fillSelect(node, options) {
  node.replaceChildren()
  for (const option of options) node.append(el('option', { value: option.value, text: option.text }))
}

function selectedValues(node) {
  return [...node.selectedOptions].map((option) => option.value)
}

function warningText(code) {
  if (code === 'maintenance') return t('warnMaintenance')
  if (code === 'unavailable') return t('warnUnavailable')
  if (code === 'truck_overlap') return t('warnTruckOverlap')
  if (code === 'worker_overlap') return t('warnWorkerOverlap')
  return code
}

function show(node, text) {
  node.hidden = false
  node.textContent = text
}

function hide(node) {
  node.hidden = true
  node.textContent = ''
}
