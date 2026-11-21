import { getLocale, t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { confirmDialog, scheduleBadge, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'
import { assignmentWarnings, blocksSave } from '../utils/schedule.js'
import { previewResidentMessage } from '../utils/templates.js'
import { addisLocalToUtc, formatAddisDate, formatAddisTime } from '../utils/time.js'

export async function renderSchedules(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', role: 'status', hidden: true })
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const warning = el('p', { class: 'note', role: 'status', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let query = ''
  let statusFilter = 'all'

  const area = el('select', { required: true })
  const date = el('input', { type: 'date', required: true })
  const start = el('input', { type: 'time', required: true })
  const end = el('input', { type: 'time' })
  const route = el('select')
  const truck = el('select')
  const workers = el('select', { multiple: true, size: '5' })
  const submitBtn = el('button', { type: 'submit', text: t('saveDraft') })

  const previewDayBefore = el('p', { class: 'preview-item' })
  const previewSameDay = el('p', { class: 'preview-item' })
  const previewBox = el('div', { class: 'preview-box', hidden: true }, [
    el('h3', { text: t('messagePreviewTitle') }),
    el('strong', { text: t('dayBeforeLabel') }),
    previewDayBefore,
    el('strong', { text: t('sameDayLabel') }),
    previewSameDay,
  ])

  const form = el('form', { class: 'panel panel-pad' }, [
    el('h2', { text: t('saveDraft') }),
    el('div', { class: 'form-grid' }, [
      field(t('area'), area),
      field(t('collectionDate'), date),
      field(t('startTime'), start),
      field(t('endTime'), end),
      field(t('routes'), route),
      field(t('trucks'), truck),
    ]),
    field(t('workers'), workers),
    warning,
    previewBox,
    submitBtn,
  ])

  const filterBar = el('div', { class: 'filter-pills', role: 'group', 'aria-label': t('status') })
  const listPanel = el('section', { class: 'panel' }, [
    el('div', { class: 'list-toolbar' }, [
      searchInput({
        placeholder: t('searchPlaceholder'),
        onInput: (value) => {
          query = value
          drawList()
        },
      }),
      filterBar,
    ]),
    tableHost,
  ])

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('schedules') }),
      el('p', { class: 'muted', text: t('mapDisclaimer') }),
    ]),
    status,
    error,
    form,
    listPanel,
  )

  tableHost.replaceChildren(skeletonTable(4))

  let schedules = []
  let areaName = new Map()
  const statuses = ['all', 'draft', 'published', 'assigned', 'on_the_way', 'in_progress', 'completed', 'delayed', 'cancelled']
  const drawFilters = () => {
    filterBar.replaceChildren(...statuses.map((s) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: s === 'all' ? t('allFilter') : t(`status_${s}`),
      'aria-pressed': statusFilter === s ? 'true' : 'false',
      onclick: () => {
        statusFilter = s
        drawFilters()
        drawList()
      },
    })))
  }

  const openReasonDialog = ({ title, confirmLabel }) => new Promise((resolve) => {
    const dialog = el('dialog', { class: 'modal' })
    const input = el('textarea', { required: true, maxlength: '300' })
    const err = el('p', { class: 'error', hidden: true })
    const okBtn = el('button', { type: 'submit', text: confirmLabel })
    const cancelBtn = el('button', {
      type: 'button',
      class: 'secondary',
      text: t('cancel'),
      onclick: () => {
        dialog.close()
        resolve(null)
      },
    })
    const dlgForm = el('form', {}, [
      el('h3', { text: title }),
      err,
      field(t('reasonLabel'), input),
      el('div', { class: 'modal-actions' }, [cancelBtn, okBtn]),
    ])
    dlgForm.addEventListener('submit', (ev) => {
      ev.preventDefault()
      const val = input.value.trim()
      if (!val) {
        err.hidden = false
        err.textContent = t('reasonRequired')
        return
      }
      dialog.close()
      resolve(val)
    })
    dialog.append(dlgForm)
    dialog.addEventListener('cancel', () => resolve(null))
    dialog.addEventListener('close', () => dialog.remove())
    document.body.append(dialog)
    dialog.showModal()
    input.focus()
  })

  const openRescheduleDialog = (item) => {
    const dialog = el('dialog', { class: 'modal modal-wide' })
    const dInput = el('input', { type: 'date', required: true, value: item.collection_date })
    const sInput = el('input', { type: 'time', required: true })
    const eInput = el('input', { type: 'time' })
    const rInput = el('textarea', { required: true, maxlength: '300' })
    const err = el('p', { class: 'error', hidden: true })
    const preview = el('p', { class: 'preview-item muted' })
    const saveBtn = el('button', { type: 'submit', text: t('reschedule') })
    const cancelBtn = el('button', {
      type: 'button',
      class: 'secondary',
      text: t('cancel'),
      onclick: () => dialog.close(),
    })

    const updatePreview = () => {
      const iso = addisLocalToUtc(dInput.value, sInput.value)
      preview.textContent = iso
        ? previewResidentMessage({ type: 'reschedule', locale: getLocale(), expectedStartIso: iso })
        : ''
    }
    dInput.addEventListener('change', updatePreview)
    sInput.addEventListener('change', updatePreview)

    const dlgForm = el('form', {}, [
      el('h3', { text: `${t('reschedule')} — ${areaName.get(item.area_id) ?? ''}` }),
      err,
      el('div', { class: 'form-grid' }, [
        field(t('collectionDate'), dInput),
        field(t('startTime'), sInput),
        field(t('endTime'), eInput),
      ]),
      field(t('reasonLabel'), rInput),
      preview,
      el('div', { class: 'modal-actions' }, [cancelBtn, saveBtn]),
    ])

    dlgForm.addEventListener('submit', async (ev) => {
      ev.preventDefault()
      err.hidden = true
      const startIso = addisLocalToUtc(dInput.value, sInput.value)
      const endIso = eInput.value ? addisLocalToUtc(dInput.value, eInput.value) : null
      const reason = rInput.value.trim()
      if (!startIso || new Date(startIso).getTime() <= Date.now()) {
        err.hidden = false
        err.textContent = t('pastTime')
        return
      }
      if (endIso && new Date(endIso).getTime() <= new Date(startIso).getTime()) {
        err.hidden = false
        err.textContent = t('endBeforeStart')
        return
      }
      if (!reason) {
        err.hidden = false
        err.textContent = t('reasonRequired')
        return
      }
      setBusy(saveBtn, true, t('reschedule'))
      const { data, error: rpcErr } = await supabase.rpc('reschedule_collection', {
        target_schedule: item.id,
        new_date: dInput.value,
        new_expected_start: startIso,
        new_expected_end: endIso,
        reason,
      })
      setBusy(saveBtn, false, t('reschedule'))
      if (rpcErr) {
        err.hidden = false
        err.textContent = rpcErr.message || t('scheduleStatusFailed')
        return
      }
      item.collection_date = data?.collection_date ?? dInput.value
      item.expected_start = data?.expected_start ?? startIso
      item.expected_end = data?.expected_end ?? endIso
      if (data?.status) item.status = data.status
      toast(t('scheduleRescheduled'), 'success')
      dialog.close()
      drawList()
    })

    dialog.append(dlgForm)
    dialog.addEventListener('close', () => dialog.remove())
    document.body.append(dialog)
    dialog.showModal()
  }

  const openHistoryDialog = async (item) => {
    const dialog = el('dialog', { class: 'modal modal-wide' })
    const listHost = el('div', {}, [el('p', { class: 'muted', text: t('loading') })])
    const closeBtn = el('button', {
      type: 'button',
      class: 'secondary',
      text: t('close'),
      onclick: () => dialog.close(),
    })
    dialog.append(
      el('h3', { text: `${t('history')} — ${areaName.get(item.area_id) ?? ''}` }),
      listHost,
      el('div', { class: 'modal-actions' }, [closeBtn]),
    )
    dialog.addEventListener('close', () => dialog.remove())
    document.body.append(dialog)
    dialog.showModal()

    const { data, error: hErr } = await supabase
      .from('schedule_history')
      .select('id, action, changed_at, previous, new, reason')
      .eq('schedule_id', item.id)
      .order('changed_at', { ascending: false })
    if (hErr || !data || data.length === 0) {
      listHost.replaceChildren(el('p', { class: 'muted', text: t('noHistory') }))
      return
    }
    const ul = el('ul', { class: 'history-list' })
    for (const row of data) {
      const when = `${formatAddisDate(row.changed_at)} · ${formatAddisTime(row.changed_at)}`
      const nextStatus = row.new?.status ? ` → ${row.new.status}` : ''
      const prevStatus = row.previous?.status ? `${row.previous.status}` : ''
      const summary = `${row.action}${prevStatus || nextStatus ? `: ${prevStatus}${nextStatus}` : ''}`
      ul.append(el('li', { class: 'history-item' }, [
        el('div', { class: 'strong-cell', text: summary }),
        el('div', { class: 'mono muted', text: when }),
        row.reason ? el('div', { text: row.reason }) : null,
      ]))
    }
    listHost.replaceChildren(ul)
  }

  const drawList = () => {
    const filtered = schedules.filter((item) => {
      if (statusFilter !== 'all' && item.status !== statusFilter) return false
      if (!query) return true
      const label = areaName.get(item.area_id) ?? ''
      return `${label} ${item.collection_date} ${t(`status_${item.status}`)}`.toLowerCase().includes(query)
    })
    if (schedules.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    if (filtered.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('noMatches') }))
      return
    }

    const transition = async (item, nextStatus, btn, label) => {
      let reason = null
      if (nextStatus === 'published') {
        const previewText = previewResidentMessage({
          type: 'day_before',
          locale: getLocale(),
          expectedStartIso: item.expected_start,
        })
        const ok = await confirmDialog({
          title: t('confirmPublishTitle'),
          body: `${t('confirmPublishBody')}\n\n${previewText}`,
          confirmLabel: t('publish'),
        })
        if (!ok) return
      } else if (nextStatus === 'delayed' || nextStatus === 'cancelled') {
        reason = await openReasonDialog({
          title: nextStatus === 'delayed' ? t('delay') : t('cancelSchedule'),
          confirmLabel: nextStatus === 'delayed' ? t('delay') : t('cancelSchedule'),
        })
        if (!reason) return
      }
      hide(status)
      hide(error)
      setBusy(btn, true, label)
      const { error: rpcError } = await supabase.rpc('update_schedule_status', {
        target_schedule: item.id,
        next_status: nextStatus,
        reason,
      })
      setBusy(btn, false, label)
      if (rpcError) {
        show(error, rpcError.message || t('scheduleStatusFailed'))
        toast(t('scheduleStatusFailed'), 'error')
        return
      }
      item.status = nextStatus
      const msg = nextStatus === 'published'
        ? t('schedulePublished')
        : nextStatus === 'assigned'
          ? t('scheduleAssigned')
          : nextStatus === 'delayed'
            ? t('scheduleDelayed')
            : t('scheduleCancelled')
      show(status, msg)
      toast(msg, 'success')
      drawList()
    }

    const body = el('tbody')
    for (const item of filtered) {
      const when = `${formatAddisDate(item.expected_start)} · ${formatAddisTime(item.expected_start)}`
      const buttons = []
      const terminal = item.status === 'completed' || item.status === 'cancelled'
      if (item.status === 'draft') {
        const btn = el('button', {
          type: 'button',
          class: 'btn-sm',
          text: t('publish'),
          onclick: () => transition(item, 'published', btn, t('publish')),
        })
        buttons.push(btn)
      }
      if (item.status === 'published' && (item.worker_ids?.length ?? 0) > 0) {
        const btn = el('button', {
          type: 'button',
          class: 'secondary btn-sm',
          text: t('markAssigned'),
          onclick: () => transition(item, 'assigned', btn, t('markAssigned')),
        })
        buttons.push(btn)
      }
      if (!terminal) {
        buttons.push(el('button', {
          type: 'button',
          class: 'secondary btn-sm',
          text: t('reschedule'),
          onclick: () => openRescheduleDialog(item),
        }))
      }
      if (['published', 'assigned', 'on_the_way', 'in_progress'].includes(item.status)) {
        const delayBtn = el('button', {
          type: 'button',
          class: 'secondary btn-sm',
          text: t('delay'),
          onclick: () => transition(item, 'delayed', delayBtn, t('delay')),
        })
        buttons.push(delayBtn)
      }
      if (!terminal && item.status !== 'draft') {
        const cancelBtn = el('button', {
          type: 'button',
          class: 'secondary btn-sm',
          text: t('cancelSchedule'),
          onclick: () => transition(item, 'cancelled', cancelBtn, t('cancelSchedule')),
        })
        buttons.push(cancelBtn)
      }
      buttons.push(el('button', {
        type: 'button',
        class: 'secondary btn-sm',
        text: t('history'),
        onclick: () => openHistoryDialog(item),
      }))

      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: areaName.get(item.area_id) ?? '' }),
        el('td', { class: 'mono', text: when }),
        el('td', {}, [scheduleBadge(item.status)]),
        el('td', { class: 'cell-end' }, [el('div', { class: 'row-actions' }, buttons)]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
      el('thead', {}, [el('tr', {}, [
        el('th', { text: t('area') }),
        el('th', { text: t('expected') }),
        el('th', { text: t('status') }),
        el('th', { text: t('actions') }),
      ])]),
      body,
    ]))
  }

  drawFilters()

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
    tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
    return
  }

  const areas = areaResult.data ?? []
  const routes = routeResult.data ?? []
  const trucks = truckResult.data ?? []
  const workerRows = workerResult.data ?? []
  const links = linkResult.data ?? []
  schedules = (scheduleResult.data ?? []).map((item) => ({
    ...item,
    worker_ids: links.filter((link) => link.schedule_id === item.id).map((link) => link.worker_id),
  }))
  areaName = new Map(areas.map((item) => [item.id, `${item.kebele_code} — ${item.name}`]))
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
  const refreshWarningsAndPreview = () => {
    const startIso = addisLocalToUtc(date.value, start.value)
    const endIso = end.value ? addisLocalToUtc(date.value, end.value) : null
    if (!startIso) {
      hide(warning)
      previewBox.hidden = true
      return
    }
    previewBox.hidden = false
    previewDayBefore.textContent = previewResidentMessage({
      type: 'day_before',
      locale: getLocale(),
      expectedStartIso: startIso,
    })
    previewSameDay.textContent = previewResidentMessage({
      type: 'same_day',
      locale: getLocale(),
      expectedStartIso: startIso,
    })
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
  area.addEventListener('change', refreshRoutes)
  for (const input of [date, start, end, truck, workers]) {
    input.addEventListener('change', refreshWarningsAndPreview)
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
      toast(t('warnMaintenance'), 'error')
      return
    }
    setBusy(submitBtn, true, t('saveDraft'))
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
      setBusy(submitBtn, false, t('saveDraft'))
      show(error, t('scheduleFailed'))
      toast(t('scheduleFailed'), 'error')
      return
    }
    if (workerIds.length) {
      const { error: workerError } = await supabase.from('schedule_workers').insert(
        workerIds.map((workerId) => ({ schedule_id: created.id, worker_id: workerId })),
      )
      if (workerError) {
        await supabase.from('collection_schedules').delete().eq('id', created.id)
        setBusy(submitBtn, false, t('saveDraft'))
        show(error, t('scheduleFailed'))
        toast(t('scheduleFailed'), 'error')
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
    setBusy(submitBtn, false, t('saveDraft'))
    if (historyError) {
      await supabase.from('collection_schedules').delete().eq('id', created.id)
      show(error, t('scheduleFailed'))
      toast(t('scheduleFailed'), 'error')
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
    previewBox.hidden = true
    hide(warning)
    show(status, t('scheduleSaved'))
    toast(t('scheduleSaved'), 'success')
    drawList()
  })

  drawList()
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
