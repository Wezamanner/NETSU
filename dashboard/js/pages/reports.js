import { t } from '../i18n.js'
import { mountMap, setMarkers } from '../map/osm.js'
import { supabase } from '../supabase-client.js'
import { badge, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'
import { formatAddisDate, formatAddisTime } from '../utils/time.js'

const STATUS_TONE = {
  received: 'warning',
  assigned: 'info',
  in_progress: 'info',
  completed: 'success',
  cancelled: 'danger',
}

const STATUS_COLOR = {
  received: '#d97706',
  assigned: '#0284c7',
  in_progress: '#2563eb',
  completed: '#0f6b4c',
  cancelled: '#b91c1c',
}

export async function renderReports(outlet) {
  clear(outlet)
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  const mapHost = el('div', { class: 'osm-map', role: 'region', 'aria-label': t('reportsMapTitle') })
  const filterBar = el('div', { class: 'filter-pills', role: 'group', 'aria-label': t('status') })

  let reports = []
  let areaMap = new Map()
  let workers = []
  let trucks = []
  let query = ''
  let statusFilter = 'all'

  const statuses = ['all', 'received', 'assigned', 'in_progress', 'completed', 'cancelled']
  const drawFilters = () => {
    filterBar.replaceChildren(...statuses.map((s) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: s === 'all' ? t('allFilter') : t(`report_${s}`),
      'aria-pressed': statusFilter === s ? 'true' : 'false',
      onclick: () => {
        statusFilter = s
        drawFilters()
        draw()
      },
    })))
  }

  const openEditor = async (report) => {
    const dialog = el('dialog', { class: 'modal modal-wide' })
    const statusSel = el('select')
    for (const s of ['received', 'assigned', 'in_progress', 'completed', 'cancelled']) {
      statusSel.append(el('option', { value: s, text: t(`report_${s}`) }))
    }
    statusSel.value = report.status

    const workerSel = el('select')
    workerSel.append(el('option', { value: '', text: t('unassigned') }))
    for (const w of workers) {
      workerSel.append(el('option', { value: w.id, text: w.full_name }))
    }
    workerSel.value = report.assigned_worker_id ?? ''

    const truckSel = el('select')
    truckSel.append(el('option', { value: '', text: t('unassigned') }))
    for (const tr of trucks) {
      truckSel.append(el('option', { value: tr.id, text: tr.plate_number }))
    }
    truckSel.value = report.assigned_truck_id ?? ''

    const noteInput = el('textarea', { maxlength: '500' })
    noteInput.value = report.admin_note ?? ''

    const photoSlot = el('div', {}, [el('p', { class: 'muted', text: report.image_path ? t('loading') : t('noPhoto') })])

    const saveBtn = el('button', { type: 'submit', text: t('saveChanges') })
    const closeBtn = el('button', {
      type: 'button',
      class: 'secondary',
      text: t('close'),
      onclick: () => dialog.close(),
    })

    const form = el('form', {}, [
      el('h3', { text: t('reportDetails') }),
      el('p', { class: 'strong-cell', text: areaMap.get(report.area_id) ?? '' }),
      el('p', { text: report.description }),
      report.address ? el('p', { class: 'muted', text: report.address }) : null,
      el('div', { class: 'field' }, [
        el('span', { class: 'label', text: t('reportPhoto') }),
        photoSlot,
      ]),
      el('div', { class: 'form-grid' }, [
        field(t('status'), statusSel),
        field(t('assignedWorker'), workerSel),
        field(t('assignedTruck'), truckSel),
      ]),
      field(t('adminNote'), noteInput),
      el('div', { class: 'modal-actions' }, [closeBtn, saveBtn]),
    ])

    form.addEventListener('submit', async (ev) => {
      ev.preventDefault()
      setBusy(saveBtn, true, t('saveChanges'))
      const nextStatus = statusSel.value
      const payload = {
        status: nextStatus,
        assigned_worker_id: workerSel.value || null,
        assigned_truck_id: truckSel.value || null,
        admin_note: noteInput.value.trim() || null,
        completed_at: nextStatus === 'completed' ? (report.completed_at ?? new Date().toISOString()) : null,
      }
      const { error: updateErr } = await supabase
        .from('garbage_reports')
        .update(payload)
        .eq('id', report.id)
      setBusy(saveBtn, false, t('saveChanges'))
      if (updateErr) {
        toast(t('reportUpdateFailed'), 'error')
        return
      }
      Object.assign(report, payload)
      toast(t('reportUpdated'), 'success')
      dialog.close()
      draw()
    })

    dialog.append(form)
    dialog.addEventListener('close', () => dialog.remove())
    document.body.append(dialog)
    dialog.showModal()

    if (report.image_path) {
      const { data: signed } = await supabase.storage
        .from('report-images')
        .createSignedUrl(report.image_path, 300)
      if (signed?.signedUrl) {
        photoSlot.replaceChildren(el('img', {
          class: 'report-photo',
          src: signed.signedUrl,
          alt: t('reportPhoto'),
        }))
      } else {
        photoSlot.replaceChildren(el('p', { class: 'muted', text: t('noPhoto') }))
      }
    }
  }

  const draw = () => {
    const filtered = reports.filter((r) => {
      if (statusFilter !== 'all' && r.status !== statusFilter) return false
      if (!query) return true
      const areaLabel = areaMap.get(r.area_id) ?? ''
      return `${areaLabel} ${r.description} ${r.address ?? ''} ${r.status}`.toLowerCase().includes(query)
    })

    const markers = filtered
      .filter((r) => typeof r.lat === 'number' && typeof r.lng === 'number')
      .map((r) => ({
        lat: r.lat,
        lng: r.lng,
        color: STATUS_COLOR[r.status] ?? '#0f6b4c',
        label: `${areaMap.get(r.area_id) ?? ''} (${t(`report_${r.status}`)}) — ${r.description}`,
      }))
    setMarkers(mapHost, markers, { fitBounds: markers.length > 0 })

    if (reports.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    if (filtered.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('noMatches') }))
      return
    }
    const workerMap = new Map(workers.map((w) => [w.id, w.full_name]))
    const truckMap = new Map(trucks.map((tr) => [tr.id, tr.plate_number]))
    const body = el('tbody')
    for (const r of filtered) {
      const when = `${formatAddisDate(r.created_at)} · ${formatAddisTime(r.created_at)}`
      const assigned = [
        r.assigned_worker_id ? workerMap.get(r.assigned_worker_id) : null,
        r.assigned_truck_id ? truckMap.get(r.assigned_truck_id) : null,
      ].filter(Boolean).join(' · ') || t('unassigned')
      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: areaMap.get(r.area_id) ?? '' }),
        el('td', { text: r.description }),
        el('td', { class: 'mono', text: when }),
        el('td', { text: assigned }),
        el('td', {}, [badge(t(`report_${r.status}`), STATUS_TONE[r.status] ?? 'neutral', 'reports')]),
        el('td', { class: 'cell-end' }, [
          el('button', {
            type: 'button',
            class: 'secondary btn-sm',
            text: t('reportDetails'),
            onclick: () => openEditor(r),
          }),
        ]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
      el('thead', {}, [el('tr', {}, [
        el('th', { text: t('area') }),
        el('th', { text: t('description') }),
        el('th', { text: t('expected') }),
        el('th', { text: t('assignedWorker') }),
        el('th', { text: t('status') }),
        el('th', { text: t('actions') }),
      ])]),
      body,
    ]))
  }

  drawFilters()
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('reports') }),
      el('p', { class: 'muted', text: t('reportsHelp') }),
    ]),
    error,
    el('section', { class: 'panel panel-pad' }, [
      el('h2', { text: t('reportsMapTitle') }),
      mapHost,
    ]),
    el('section', { class: 'panel' }, [
      el('div', { class: 'list-toolbar' }, [
        searchInput({
          placeholder: t('searchPlaceholder'),
          onInput: (val) => {
            query = val
            draw()
          },
        }),
        filterBar,
      ]),
      tableHost,
    ]),
  )

  mountMap(mapHost)
  tableHost.replaceChildren(skeletonTable(5))

  const [repRes, areaRes, workerRes, truckRes] = await Promise.all([
    supabase
      .from('garbage_reports')
      .select('id, resident_id, area_id, address, lat, lng, description, image_path, status, assigned_worker_id, assigned_truck_id, admin_note, completed_at, created_at')
      .order('created_at', { ascending: false })
      .limit(200),
    supabase.from('service_areas').select('id, name, kebele_code'),
    supabase.from('profiles').select('id, full_name').eq('role', 'worker').eq('active', true).order('full_name'),
    supabase.from('trucks').select('id, plate_number').order('plate_number'),
  ])

  if (repRes.error) {
    error.hidden = false
    error.textContent = t('setupBody')
    tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
    return
  }

  reports = repRes.data ?? []
  areaMap = new Map((areaRes.data ?? []).map((a) => [a.id, `${a.kebele_code} — ${a.name}`]))
  workers = workerRes.data ?? []
  trucks = truckRes.data ?? []
  draw()
}
