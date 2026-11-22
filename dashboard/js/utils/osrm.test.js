import assert from 'node:assert/strict'
import test from 'node:test'
import { fetchDrivingLine, geojsonLineToPoints, osrmCoordinatePath } from './osrm.js'

test('builds an OSRM coordinate path as lng,lat', () => {
  assert.equal(
    osrmCoordinatePath([
      { lat: 7.67, lng: 36.83 },
      { lat: 7.68, lng: 36.84 },
    ]),
    '36.83,7.67;36.84,7.68',
  )
})

test('reads a GeoJSON line into map points', () => {
  const points = geojsonLineToPoints({
    type: 'LineString',
    coordinates: [
      [36.83, 7.67],
      [36.84, 7.68],
    ],
  })
  assert.deepEqual(points, [
    { lat: 7.67, lng: 36.83 },
    { lat: 7.68, lng: 36.84 },
  ])
})

test('uses the driving geometry when OSRM answers', async () => {
  const fetchImpl = async (url) => {
    assert.match(url, /36\.83,7\.67;36\.84,7\.68/)
    return {
      ok: true,
      json: async () => ({
        routes: [{ geometry: { coordinates: [[36.83, 7.67], [36.835, 7.675], [36.84, 7.68]] } }],
      }),
    }
  }
  const line = await fetchDrivingLine(
    [
      { lat: 7.67, lng: 36.83 },
      { lat: 7.68, lng: 36.84 },
    ],
    { fetchImpl, osrmUrl: 'https://router.example/route/v1/driving' },
  )
  assert.equal(line.length, 3)
  assert.equal(line[1].lat, 7.675)
})

test('keeps the straight stop line when OSRM fails', async () => {
  const stops = [
    { lat: 7.67, lng: 36.83 },
    { lat: 7.68, lng: 36.84 },
  ]
  const line = await fetchDrivingLine(stops, {
    osrmUrl: 'https://router.example/route/v1/driving',
    fetchImpl: async () => ({ ok: false, json: async () => ({}) }),
  })
  assert.deepEqual(line, stops)
})
