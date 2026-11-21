import { t } from '../i18n.js'
import { mountMap, setMarkers } from '../map/osm.js'
import { supabase } from '../supabase-client.js'
import { badge } from '../ui/components.js'
import { el } from '../ui/dom.js'
import { icon } from '../ui/icons.js'
import { addisDateKey } from '../utils/time.js'

export async function renderHome(outlet) {
  const today = addisDateKey()
  const scheduleVal = el('strong', { text: '…' })
  const reportVal = el('strong', { text: '…' })
  const deliveryVal = el('strong', { class: 'stat-compact', text: '…' })
  const mapCount = el('span', { class: 'map-badge-slot' })
  const mapHost = el('div', { class: 'osm-map', role: 'region', 'aria-label': t('mapTitle') })

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('dashboard') }),
      el('p', { class: 'muted', text: t('welcome') }),
    ]),
    el('div', { class: 'grid' }, [
      statCard(t('todaySchedules'), scheduleVal, 'schedules', '#/schedules'),
      statCard(t('pendingReports'), reportVal, 'reports', '#/reports'),
      statCard(t('delivery'), deliveryVal, 'bell', null),
    ]),
    el('section', { class: 'panel panel-pad' }, [
      el('div', { class: 'panel-head' }, [
        el('div', {}, [
          el('h2', { text: t('mapTitle') }),
          el('p', { class: 'muted', text: t('mapDisclaimer') }),
        ]),
        mapCount,
      ]),
      mapHost,
    ]),
  )

  mountMap(mapHost)

  const [schedules, reports, delivery, areaRes] = await Promise.all([
    count('collection_schedules', (query) => query.eq('collection_date', today).neq('status', 'draft')),
    count('garbage_reports', (query) => query.in('status', ['received', 'assigned', 'in_progress'])),
    deliveryCounts(),
    supabase.from('service_areas').select('name, center_lat, center_lng').eq('active', true),
  ])

  scheduleVal.textContent = schedules
  reportVal.textContent = reports
  deliveryVal.textContent = delivery

  const markers = (areaRes.data ?? [])
    .filter((area) => area.center_lat != null && area.center_lng != null)
    .map((area) => ({ lat: area.center_lat, lng: area.center_lng, label: area.name }))
  mapCount.replaceChildren(badge(`${markers.length} ${t('activeAreasCount')}`, 'info', 'areas'))
  if (markers.length === 0) {
    setMarkers(mapHost, [{ lat: 7.6667, lng: 36.8333, label: 'Jimma' }])
  } else {
    setMarkers(mapHost, markers)
  }
}

function statCard(label, valueNode, iconName, href) {
  const inner = [
    el('div', { class: 'stat-top' }, [
      el('span', { class: 'stat-icon' }, [icon(iconName, 20)]),
      href ? el('span', { class: 'stat-arrow' }, [icon('arrowRight', 16)]) : null,
    ]),
    el('span', { class: 'muted stat-label', text: label }),
    valueNode,
  ]
  if (href) {
    return el('a', { class: 'panel stat stat-link', href }, inner)
  }
  return el('article', { class: 'panel stat' }, inner)
}

async function count(table, refine) {
  const query = refine(supabase.from(table).select('id', { count: 'exact', head: true }))
  const { count: total, error } = await query
  if (error) return '—'
  return String(total ?? 0)
}

async function deliveryCounts() {
  const { data, error } = await supabase.from('notifications').select('delivery_status')
  if (error) return '—'
  const totals = { sent: 0, failed: 0, pending: 0 }
  for (const row of data ?? []) {
    if (row.delivery_status in totals) totals[row.delivery_status] += 1
  }
  return `${t('sent')} ${totals.sent} · ${t('failed')} ${totals.failed} · ${t('pending')} ${totals.pending}`
}
