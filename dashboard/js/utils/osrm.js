/** Public OSRM helpers. Swap the base URL in map-config.js for a self-hosted router. */

export function osrmCoordinatePath(stops) {
  return stops.map((stop) => `${stop.lng},${stop.lat}`).join(';')
}

export function geojsonLineToPoints(geometry) {
  const coords = geometry?.coordinates
  if (!Array.isArray(coords)) return []
  return coords
    .filter((pair) => Array.isArray(pair) && Number.isFinite(pair[0]) && Number.isFinite(pair[1]))
    .map(([lng, lat]) => ({ lat, lng }))
}

export async function fetchDrivingLine(stops, { fetchImpl = fetch, osrmUrl } = {}) {
  if (!Array.isArray(stops) || stops.length < 2 || !osrmUrl) return stops ?? []
  const url = `${osrmUrl}/${osrmCoordinatePath(stops)}?overview=full&geometries=geojson`
  const response = await fetchImpl(url, {
    headers: {
      Accept: 'application/json',
      'User-Agent': 'NetsuJimmaWaste/1.0 (Jimma municipal dashboard)',
    },
  })
  if (!response.ok) return stops
  const body = await response.json()
  const line = geojsonLineToPoints(body?.routes?.[0]?.geometry)
  return line.length >= 2 ? line : stops
}
