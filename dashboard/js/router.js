import { renderAreas } from './pages/areas.js'
import { renderHome } from './pages/home.js'
import { renderPlaceholder } from './pages/placeholder.js'
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
  reports: (outlet) => renderPlaceholder(outlet, 'reports'),
  routes: renderRoutes,
  trucks: renderTrucks,
  workers: renderWorkers,
  feedback: (outlet) => renderPlaceholder(outlet, 'feedback'),
  analytics: (outlet) => renderPlaceholder(outlet, 'analytics'),
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
