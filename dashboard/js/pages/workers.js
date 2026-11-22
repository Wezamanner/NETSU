import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, confirmDialog, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'
import { functionErrorMessage } from '../utils/function-error.js'
import { normalizeEthiopianMobile } from '../utils/phone.js'

export async function renderWorkers(outlet) {
  clear(outlet)
  const status = el('p', { class: 'success', role: 'status', hidden: true })
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  let allRows = []
  let areas = []
  let areaName = new Map()
  let query = ''

  const newName = el('input', { required: true, maxlength: '120', autocomplete: 'name' })
  const newPhone = el('input', { required: true, placeholder: '09XXXXXXXX', autocomplete: 'tel' })
  const newPassword = el('input', { type: 'password', required: true, minlength: '8', autocomplete: 'new-password' })
  const newArea = el('select', { required: true })
  const createBtn = el('button', { type: 'submit', text: t('createAccountBtn') })
  const createForm = el('form', { class: 'panel panel-pad' }, [
    el('h2', { text: t('createWorkerTitle') }),
    el('div', { class: 'form-grid' }, [
      field(t('fullName'), newName),
      field(t('phone'), newPhone),
      field(t('password'), newPassword),
      field(t('area'), newArea),
    ]),
    createBtn,
  ])

  const draw = () => {
    const filtered = allRows.filter((worker) => {
      if (!query) return true
      return `${worker.full_name} ${worker.phone} ${areaName.get(worker.area_id) ?? ''}`.toLowerCase().includes(query)
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
    for (const worker of filtered) {
      const areaSelect = el('select', { 'aria-label': t('area') })
      areaSelect.append(el('option', { value: '', text: '—' }))
      for (const area of areas) {
        areaSelect.append(el('option', { value: area.id, text: `${area.kebele_code} — ${area.name}` }))
      }
      areaSelect.value = worker.area_id ?? ''
      areaSelect.addEventListener('change', async () => {
        const nextArea = areaSelect.value || null
        const { error: updateError } = await supabase.from('profiles').update({ area_id: nextArea }).eq('id', worker.id)
        if (updateError) {
          toast(updateError.message, 'error')
          areaSelect.value = worker.area_id ?? ''
          return
        }
        worker.area_id = nextArea
        toast(t('updateArea'), 'success')
      })

      body.append(el('tr', {}, [
        el('td', { class: 'strong-cell', text: worker.full_name }),
        el('td', { class: 'mono', text: worker.phone }),
        el('td', {}, [areaSelect]),
        el('td', {}, [
          badge(worker.active ? t('active') : t('inactive'), worker.active ? 'success' : 'neutral', worker.active ? 'check' : 'xCircle'),
        ]),
        el('td', { class: 'cell-end' }, [
          el('button', {
            type: 'button',
            class: 'secondary btn-sm',
            text: worker.active ? t('deactivate') : t('activate'),
            onclick: async () => {
              if (worker.active) {
                const ok = await confirmDialog({
                  title: t('confirmToggleTitle'),
                  body: t('confirmDeactivateBody'),
                  confirmLabel: t('deactivate'),
                })
                if (!ok) return
              }
              const { error: updateError } = await supabase
                .from('profiles')
                .update({ active: !worker.active })
                .eq('id', worker.id)
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
        el('th', { text: t('area') }),
        el('th', { text: t('active') }),
        el('th', { text: '' }),
      ])]),
      body,
    ]))
  }

  const load = async () => {
    tableHost.replaceChildren(skeletonTable(4))
    const [workersRes, areasRes] = await Promise.all([
      supabase.from('profiles').select('id, full_name, phone, active, area_id').eq('role', 'worker').order('full_name'),
      supabase.from('service_areas').select('id, name, kebele_code').eq('active', true).order('kebele_code'),
    ])
    if (workersRes.error) {
      error.hidden = false
      error.textContent = t('setupBody')
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    areas = areasRes.data ?? []
    areaName = new Map(areas.map((area) => [area.id, `${area.kebele_code} — ${area.name}`]))
    newArea.replaceChildren(
      el('option', { value: '', text: t('selectArea') }),
      ...areas.map((area) => el('option', { value: area.id, text: `${area.kebele_code} — ${area.name}` })),
    )
    allRows = workersRes.data ?? []
    draw()
  }

  createForm.addEventListener('submit', async (event) => {
    event.preventDefault()
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
    if (!newArea.value) {
      error.hidden = false
      error.textContent = t('selectArea')
      return
    }
    setBusy(createBtn, true, t('createAccountBtn'))
    const { data, error: fnErr } = await supabase.functions.invoke('admin-create-user', {
      body: {
        fullName: newName.value.trim(),
        phone,
        password: newPassword.value,
        role: 'worker',
        areaId: newArea.value,
      },
    })
    setBusy(createBtn, false, t('createAccountBtn'))
    if (fnErr || data?.error) {
      const message = data?.error || await functionErrorMessage(fnErr, t('accountCreateFailed'))
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

  const listPanel = el('section', { class: 'panel' }, [
    el('div', { class: 'list-toolbar' }, [
      searchInput({
        placeholder: t('searchPlaceholder'),
        onInput: (value) => {
          query = value
          draw()
        },
      }),
    ]),
    tableHost,
  ])

  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('workers') }),
      el('p', { class: 'muted', text: t('workersHelp') }),
    ]),
    status,
    error,
    createForm,
    listPanel,
  )
  await load()
}
