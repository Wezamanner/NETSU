import { mapConfig } from '../map-config.js'
import { escapeHtml } from '../utils/escape.js'

const maps = new WeakMap()

export function mountMap(container, { onClick } = {}) {
  if (!window.L) {
    container.textContent = 'Map library did not load.'
    return null
  }
  const map = window.L.map(container, { scrollWheelZoom: true }).setView(mapConfig.center, mapConfig.zoom)
  window.L.tileLayer(mapConfig.tileUrl, {
    attribution: mapConfig.attribution,
    maxZoom: 19,
  }).addTo(map)
  if (onClick) {
    map.on('click', (event) => onClick(event.latlng.lat, event.latlng.lng))
  }
  maps.set(container, {
    map,
    layer: window.L.layerGroup().addTo(map),
    lineLayer: window.L.layerGroup().addTo(map),
  })
  return map
}

export function setMarkers(container, markers, { fitBounds = false } = {}) {
  const record = maps.get(container)
  if (!record) return
  record.layer.clearLayers()
  const latLngs = []
  for (const marker of markers) {
    if (typeof marker.lat !== 'number' || typeof marker.lng !== 'number') continue
    const circle = window.L.circleMarker([marker.lat, marker.lng], {
      radius: marker.radius ?? 8,
      color: '#ffffff',
      weight: 2,
      fillColor: marker.color ?? '#0f6b4c',
      fillOpacity: 0.95,
    })
    if (marker.label) circle.bindPopup(escapeHtml(marker.label))
    circle.addTo(record.layer)
    latLngs.push([marker.lat, marker.lng])
  }
  if (fitBounds && latLngs.length > 1) {
    record.map.fitBounds(latLngs, { padding: [28, 28], maxZoom: 15 })
  } else if (fitBounds && latLngs.length === 1) {
    record.map.setView(latLngs[0], 14)
  }
}

export function setPolyline(container, points, { color = '#0f6b4c' } = {}) {
  const record = maps.get(container)
  if (!record) return
  record.lineLayer.clearLayers()
  const valid = points
    .filter((p) => typeof p.lat === 'number' && typeof p.lng === 'number')
    .map((p) => [p.lat, p.lng])
  if (valid.length >= 2) {
    window.L.polyline(valid, { color, weight: 4, opacity: 0.85 }).addTo(record.lineLayer)
  }
}
