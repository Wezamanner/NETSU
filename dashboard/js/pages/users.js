import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, confirmDialog, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'
import { functionErrorMessage } from '../utils/function-error.js'
import { normalizeEthiopianMobile } from '../utils/phone.js'

export async function renderUsers(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', role: 'status', hidden: true })
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let areas = []
  let currentId = null
  let query = ''
  let roleFilter = 'all'

  // Create Worker / Admin form (uses admin-create-user Edge Function)
  const newName = el('input', { required: true, maxlength: '120' })
  const newPhone = el('input', { required: true, placeholder: '09XXXXXXXX' })
  const newPassword = el('input', { type: 'password', required: true, minlength: '8' })
  const newRole = el('select', {}, [
    el('option', { value: 'resident', text: t('roleResident') }),
    el('option', { value: 'admin', text: t('roleAdmin') }),
  ])
  const newArea = el('select')
  const createBtn = el('button', { type: 'submit', text: t('createAccountBtn') })

  const createForm = el('form', { class: 'panel panel-pad' }, [
    el('h2', { text: t('createAccountTitle') }),
    el('div', { class: 'form-grid' }, [
      field(t('fullName'), newName),
      field(t('phone'), newPhone),
      field(t('password'), newPassword),
      field(t('role'), newRole),
      field(t('area'), newArea),
    ]),
    createBtn,
  ])

  const filterBar = el('div', { class: 'filter-pills', role: 'group', 'aria-label': t('role') })
  const roles = ['all', 'admin', 'worker', 'resident']
  const drawFilters = () => {
    filterBar.replaceChildren(...roles.map((r) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: r === 'all' ? t('allFilter') : r,
      'aria-pressed': roleFilter === r ? 'true' : 'false',
      onclick: () => {
        roleFilter = r
        drawFilters()
        draw()
      },
    })))
  }

  const draw = () => {
    const filtered = allRows.filter((person) => {
      if (roleFilter !== 'all' && person.role !== roleFilter) return false
      if (!query) return true
      return `${person.full_name} ${person.phone} ${person.role}`.toLowerCase().includes(query)
    })
    if (allRows.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    if (filtered.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('noMatches') }))
      return
    }
    const body = el('tbody')
    for (const person of filtered) {
      const self = person.id === currentId
      const roleTone = person.role === 'admin' ? 'info' : person.role === 'worker' ? 'warning' : 'neutral'
      const roleIcon = person.role === 'worker' ? 'workers' : 'users'

      const areaSelect = el('select', { 'aria-label': t('area') })
      areaSelect.append(el('option', { value: '', text: '—' }))
      for (const a of areas) {
        areaSelect.append(el('option', { value: a.id, text: `${a.kebele_code} — ${a.name}` }))
      }
      areaSelect.value = person.area_id ?? ''
      areaSelect.addEventListener('change', async () => {
        const nextArea = areaSelect.value || null
        const { error: upErr } = await supabase
          .from('profiles')
          .update({ area_id: nextArea })
          .eq('id', person.id)
        if (upErr) {
          toast(upErr.message, 'error')
          areaSelect.value = person.area_id ?? ''
          return
        }
        person.area_id = nextArea
        toast(t('updateArea'), 'success')
      })

      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: self ? `${person.full_name} (${t('you')})` : person.full_name }),
        el('td', { class: 'mono', text: person.phone }),
        el('td', {}, [badge(person.role, roleTone, roleIcon)]),
        el('td', {}, [areaSelect]),
        el('td', {}, [
          badge(person.active ? t('active') : t('inactive'), person.active ? 'success' : 'neutral', person.active ? 'check' : 'xCircle'),
        ]),
        el('td', { class: 'cell-end' }, [
          self
            ? ''
            : el('button', {
                type: 'button',
                class: 'secondary btn-sm',
                text: person.active ? t('deactivate') : t('activate'),
                onclick: async () => {
                  if (person.active) {
                    const ok = await confirmDialog({
                      title: t('confirmToggleTitle'),
                      body: t('confirmDeactivateBody'),
                      confirmLabel: t('deactivate'),
                    })
                    if (!ok) return
                  }
                  const { error: updateError } = await supabase
                    .from('profiles')
                    .update({ active: !person.active })
                    .eq('id', person.id)
                  if (updateError) {
                    error.hidden = false
                    error.textContent = updateError.message
                    toast(updateError.message, 'error')
                    return
                  }
                  toast(t('statusUpdated'), 'success')
                  await load()
                },
              }),
        ]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
      el('thead', {}, [el('tr', {}, [
        el('th', { text: t('fullName') }),
        el('th', { text: t('phone') }),
        el('th', { text: t('role') }),
        el('th', { text: t('area') }),
        el('th', { text: t('active') }),
        el('th', { text: '' }),
      ])]),
      body,
    ]))
  }

  const load = async () => {
    tableHost.replaceChildren(skeletonTable(5))
    const [sessionRes, profilesRes, areasRes] = await Promise.all([
      supabase.auth.getSession(),
      supabase.from('profiles').select('id, full_name, phone, role, active, area_id').order('full_name'),
      supabase.from('service_areas').select('id, name, kebele_code').eq('active', true).order('kebele_code'),
    ])
    currentId = sessionRes.data.session?.user.id ?? null
    if (profilesRes.error) {
      error.hidden = false
      error.textContent = t('setupBody')
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    areas = areasRes.data ?? []
    newArea.replaceChildren(
      el('option', { value: '', text: t('selectArea') }),
      ...areas.map((a) => el('option', { value: a.id, text: `${a.kebele_code} — ${a.name}` })),
    )
    allRows = profilesRes.data ?? []
    draw()
  }

  createForm.addEventListener('submit', async (ev) => {
    ev.preventDefault()
    status.hidden = true
    error.hidden = true
    const phone = normalizeEthiopianMobile(newPhone.value)
    if (!newName.value.trim()) {
      error.hidden = false
      error.textContent = t('fieldRequired')
      return
    }
    if (!phone) {
      error.hidden = false
      error.textContent = t('invalidPhone')
      return
    }
    if (newPassword.value.length < 8) {
      error.hidden = false
      error.textContent = t('passwordShort')
      return
    }
    if (newRole.value === 'resident' && !newArea.value) {
      error.hidden = false
      error.textContent = t('residentNeedsArea')
      newArea.focus()
      return
    }
    setBusy(createBtn, true, t('createAccountBtn'))
    const { data, error: fnErr } = await supabase.functions.invoke('admin-create-user', {
      body: {
        fullName: newName.value.trim(),
        phone,
        password: newPassword.value,
        role: newRole.value,
        areaId: newArea.value || null,
      },
    })
    setBusy(createBtn, false, t('createAccountBtn'))
    if (fnErr || data?.error) {
      const message = createUserErrorText(data?.error || await functionErrorMessage(fnErr, t('accountCreateFailed')))
      error.hidden = false
      error.textContent = message
      toast(message, 'error')
      return
    }
    newName.value = ''
    newPhone.value = ''
    newPassword.value = ''
    status.hidden = false
    status.textContent = t('accountCreated')
    toast(t('accountCreated'), 'success')
    await load()
  })

  drawFilters()
  const listPanel = el('section', { class: 'panel' }, [
    el('div', { class: 'list-toolbar' }, [
      searchInput({
        placeholder: t('searchPlaceholder'),
        onInput: (value) => {
          query = value
          draw()
        },
      }),
      filterBar,
    ]),
    tableHost,
  ])

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('users') }),
      el('p', { class: 'muted', text: t('peopleHelp') }),
    ]),
    status,
    error,
    createForm,
    listPanel,
  )
  await load()
}

function createUserErrorText(message) {
  const text = String(message ?? '')
  if (/already (been )?registered|already exists|duplicate key/i.test(text)) return t('phoneTaken')
  if (/Administrator access/i.test(text)) return t('adminSessionExpired')
  if (/Role must be worker or admin/i.test(text)) return t('functionOutdated')
  if (/Database error/i.test(text)) return `${t('accountCreateFailed')} (${text})`
  if (/Failed to send a request|non-2xx/i.test(text)) return `${t('accountCreateFailed')} (${text})`
  return text || t('accountCreateFailed')
}
