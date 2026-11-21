import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { el } from '../ui/dom.js'
import { icon } from '../ui/icons.js'
import { downloadCsv } from '../utils/csv.js'
import { formatAddisDate, formatAddisTime } from '../utils/time.js'

export async function renderAnalytics(outlet) {
  outlet.replaceChildren()
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const periodBar = el('div', { class: 'filter-pills', role: 'group' })

  const repTotal = el('strong', { text: '…' })
  const compTotal = el('strong', { text: '…' })
  const delayTotal = el('strong', { text: '…' })
  const truckTotal = el('strong', { text: '…' })

  const schedCanvas = el('canvas')
  const repCanvas = el('canvas')
  const truckCanvas = el('canvas')

  let period = '30d'
  let allSchedules = []
  let allReports = []
  let areaMap = new Map()
  let truckMap = new Map()
  let charts = []

  const exportSchedulesBtn = el('button', {
    type: 'button',
    class: 'secondary',
    text: t('exportSchedulesCsv'),
    onclick: () => {
      const { schedules } = filteredData()
      downloadCsv(
        `netsu-schedules-${period}.csv`,
        ['Area', 'Date', 'Expected Start (EAT)', 'Truck', 'Status', 'Change Reason'],
        schedules.map((s) => [
          areaMap.get(s.area_id) ?? s.area_id,
          s.collection_date,
          `${formatAddisDate(s.expected_start)} ${formatAddisTime(s.expected_start)}`,
          s.truck_id ? (truckMap.get(s.truck_id) ?? s.truck_id) : '',
          s.status,
          s.change_reason ?? '',
        ]),
      )
    },
  })

  const exportReportsBtn = el('button', {
    type: 'button',
    class: 'secondary',
    text: t('exportReportsCsv'),
    onclick: () => {
      const { reports } = filteredData()
      downloadCsv(
        `netsu-reports-${period}.csv`,
        ['Area', 'Created (EAT)', 'Status', 'Address', 'Description', 'Admin Note'],
        reports.map((r) => [
          areaMap.get(r.area_id) ?? r.area_id,
          `${formatAddisDate(r.created_at)} ${formatAddisTime(r.created_at)}`,
          r.status,
          r.address ?? '',
          r.description,
          r.admin_note ?? '',
        ]),
      )
    },
  })

  const drawPeriodButtons = () => {
    const opts = [
      { id: '7d', label: t('period7d') },
      { id: '30d', label: t('period30d') },
      { id: 'all', label: t('periodAll') },
    ]
    periodBar.replaceChildren(...opts.map((opt) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: opt.label,
      'aria-pressed': period === opt.id ? 'true' : 'false',
      onclick: () => {
        period = opt.id
        drawPeriodButtons()
        renderMetrics()
      },
    })))
  }

  const filteredData = () => {
    if (period === 'all') return { schedules: allSchedules, reports: allReports }
    const days = period === '7d' ? 7 : 30
    const cutoff = Date.now() - days * 86400 * 1000
    return {
      schedules: allSchedules.filter((s) => new Date(s.expected_start).getTime() >= cutoff),
      reports: allReports.filter((r) => new Date(r.created_at).getTime() >= cutoff),
    }
  }

  const renderMetrics = () => {
    for (const c of charts) c.destroy()
    charts = []

    const { schedules, reports } = filteredData()
    const completed = schedules.filter((s) => s.status === 'completed').length
    const delayed = schedules.filter((s) => s.status === 'delayed').length
    const withTruck = schedules.filter((s) => s.truck_id != null).length

    repTotal.textContent = String(reports.length)
    compTotal.textContent = String(completed)
    delayTotal.textContent = String(delayed)
    truckTotal.textContent = String(withTruck)

    if (!window.Chart) return

    const schedStatuses = ['draft', 'published', 'assigned', 'on_the_way', 'in_progress', 'completed', 'delayed', 'cancelled']
    const schedCounts = schedStatuses.map((st) => schedules.filter((s) => s.status === st).length)
    charts.push(new window.Chart(schedCanvas, {
      type: 'bar',
      data: {
        labels: schedStatuses.map((st) => t(`status_${st}`)),
        datasets: [{ data: schedCounts, backgroundColor: '#0f6b4c', borderRadius: 6 }],
      },
      options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } },
    }))

    const repStatuses = ['received', 'assigned', 'in_progress', 'completed', 'cancelled']
    const repCounts = repStatuses.map((st) => reports.filter((r) => r.status === st).length)
    charts.push(new window.Chart(repCanvas, {
      type: 'doughnut',
      data: {
        labels: repStatuses.map((st) => t(`report_${st}`)),
        datasets: [{
          data: repCounts,
          backgroundColor: ['#d97706', '#0284c7', '#2563eb', '#0f6b4c', '#b91c1c'],
        }],
      },
      options: { responsive: true, maintainAspectRatio: false },
    }))

    const usageByTruck = new Map()
    for (const s of schedules) {
      if (!s.truck_id) continue
      const plate = truckMap.get(s.truck_id) ?? s.truck_id
      usageByTruck.set(plate, (usageByTruck.get(plate) ?? 0) + 1)
    }
    const truckLabels = [...usageByTruck.keys()]
    const truckValues = [...usageByTruck.values()]
    charts.push(new window.Chart(truckCanvas, {
      type: 'bar',
      data: {
        labels: truckLabels.length ? truckLabels : [t('noTruck')],
        datasets: [{ data: truckValues.length ? truckValues : [0], backgroundColor: '#0284c7', borderRadius: 6 }],
      },
      options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } },
    }))
  }

  drawPeriodButtons()
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('analytics') }),
      el('p', { class: 'muted', text: t('analyticsHelp') }),
    ]),
    error,
    el('div', { class: 'toolbar' }, [
      periodBar,
      el('div', { class: 'actions' }, [exportSchedulesBtn, exportReportsBtn]),
    ]),
    el('div', { class: 'grid' }, [
      kpiCard(t('reportsReceived'), repTotal, 'reports'),
      kpiCard(t('collectionsCompleted'), compTotal, 'check'),
      kpiCard(t('delayedCollections'), delayTotal, 'clock'),
      kpiCard(t('activeTruckTrips'), truckTotal, 'trucks'),
    ]),
    el('div', { class: 'chart-grid' }, [
      el('section', { class: 'panel panel-pad' }, [
        el('h2', { text: t('chartSchedulesByStatus') }),
        el('div', { class: 'chart-wrap' }, [schedCanvas]),
      ]),
      el('section', { class: 'panel panel-pad' }, [
        el('h2', { text: t('chartReportsByStatus') }),
        el('div', { class: 'chart-wrap' }, [repCanvas]),
      ]),
      el('section', { class: 'panel panel-pad' }, [
        el('h2', { text: t('chartTruckUsage') }),
        el('div', { class: 'chart-wrap' }, [truckCanvas]),
      ]),
    ]),
  )

  const [schedRes, repRes, areaRes, truckRes] = await Promise.all([
    supabase
      .from('collection_schedules')
      .select('id, area_id, collection_date, expected_start, truck_id, status, change_reason')
      .order('expected_start', { ascending: false })
      .limit(500),
    supabase
      .from('garbage_reports')
      .select('id, area_id, status, address, description, admin_note, created_at')
      .order('created_at', { ascending: false })
      .limit(500),
    supabase.from('service_areas').select('id, name, kebele_code'),
    supabase.from('trucks').select('id, plate_number'),
  ])

  if (schedRes.error || repRes.error) {
    error.hidden = false
    error.textContent = t('setupBody')
    return
  }

  allSchedules = schedRes.data ?? []
  allReports = repRes.data ?? []
  areaMap = new Map((areaRes.data ?? []).map((a) => [a.id, `${a.kebele_code} — ${a.name}`]))
  truckMap = new Map((truckRes.data ?? []).map((tr) => [tr.id, tr.plate_number]))
  renderMetrics()
}

function kpiCard(label, valueNode, iconName) {
  return el('article', { class: 'panel stat' }, [
    el('div', { class: 'stat-top' }, [
      el('span', { class: 'stat-icon' }, [icon(iconName, 20)]),
    ]),
    el('span', { class: 'muted stat-label', text: label }),
    valueNode,
  ])
}
