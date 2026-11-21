/** Public OpenStreetMap endpoints. Swap these if the pilot outgrows the public servers. */
export const mapConfig = {
  tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  nominatimUrl: 'https://nominatim.openstreetmap.org',
  osrmUrl: 'https://router.project-osrm.org/route/v1/driving',
  attribution: '&copy; OpenStreetMap contributors',
  center: [7.6667, 36.8333],
  zoom: 13,
}
