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
  maps.set(container, { map, layer: window.L.layerGroup().addTo(map) })
  return map
}

export function setMarkers(container, markers) {
  const record = maps.get(container)
  if (!record) return
  record.layer.clearLayers()
  for (const marker of markers) {
    const circle = window.L.circleMarker([marker.lat, marker.lng], {
      radius: 8,
      color: '#ffffff',
      weight: 2,
      fillColor: '#0f6b4c',
      fillOpacity: 0.95,
    })
    circle.bindPopup(escapeHtml(marker.label))
    circle.addTo(record.layer)
  }
}
