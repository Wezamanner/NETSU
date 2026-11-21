import { renderAnalytics } from './pages/analytics.js'
import { renderAreas } from './pages/areas.js'
import { renderFeedback } from './pages/feedback.js'
import { renderHome } from './pages/home.js'
import { renderReports } from './pages/reports.js'
import { renderRoutes } from './pages/routes.js'
import { renderSchedules } from './pages/schedules.js'
import { renderTrucks } from './pages/trucks.js'
import { renderUsers } from './pages/users.js'
import { renderWorkers } from './pages/workers.js'
import { clear } from './ui/dom.js'

const routes = {
  '': renderHome,
  areas: renderAreas,
  users: renderUsers,
  schedules: renderSchedules,
  reports: renderReports,
  routes: renderRoutes,
  trucks: renderTrucks,
  workers: renderWorkers,
  feedback: renderFeedback,
  analytics: renderAnalytics,
}

export function currentRoute() {
  return window.location.hash.replace(/^#\/?/, '').split('?')[0]
}

export async function drawRoute(outlet) {
  clear(outlet)
  const id = currentRoute()
  const render = routes[id] ?? routes['']
  document.querySelectorAll('.nav a').forEach((link) => {
    const target = link.getAttribute('href')?.replace('#/', '') ?? ''
    if (target === id) link.setAttribute('aria-current', 'page')
    else link.removeAttribute('aria-current')
  })
  await render(outlet)
}

export function startRouter(outlet) {
  window.addEventListener('hashchange', () => {
    drawRoute(outlet)
  })
  return drawRoute(outlet)
}
