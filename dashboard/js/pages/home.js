import { t } from '../i18n.js'
import { mountMap, setMarkers } from '../map/osm.js'
import { supabase } from '../supabase-client.js'
import { el } from '../ui/dom.js'
import { addisDateKey } from '../utils/time.js'

export async function renderHome(outlet) {
  const today = addisDateKey()
  const [schedules, reports, delivery] = await Promise.all([
    count('collection_schedules', (query) => query.eq('collection_date', today).neq('status', 'draft')),
    count('garbage_reports', (query) => query.in('status', ['received', 'assigned', 'in_progress'])),
    deliveryCounts(),
  ])

  const mapHost = el('div', { class: 'osm-map', role: 'region', 'aria-label': t('mapTitle') })
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('dashboard') }),
      el('p', { class: 'muted', text: t('welcome') }),
    ]),
    el('div', { class: 'grid' }, [
      stat(t('todaySchedules'), schedules),
      stat(t('pendingReports'), reports),
      stat(t('delivery'), delivery),
    ]),
    el('section', { class: 'panel', style: 'padding:16px' }, [
      el('h2', { text: t('mapTitle') }),
      el('p', { class: 'muted', text: t('mapDisclaimer') }),
      mapHost,
    ]),
  )
  mountMap(mapHost)
  const { data } = await supabase
    .from('service_areas')
    .select('name, center_lat, center_lng')
    .eq('active', true)
  const markers = (data ?? [])
    .filter((area) => area.center_lat != null && area.center_lng != null)
    .map((area) => ({ lat: area.center_lat, lng: area.center_lng, label: area.name }))
  if (markers.length === 0) {
    setMarkers(mapHost, [{ lat: 7.6667, lng: 36.8333, label: 'Jimma' }])
  } else {
    setMarkers(mapHost, markers)
  }
}

function stat(label, value) {
  return el('article', { class: 'panel stat' }, [
    el('span', { class: 'muted', text: label }),
    el('strong', { text: value }),
  ])
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
