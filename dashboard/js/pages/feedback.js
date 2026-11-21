import { t } from '../i18n.js'
import { supabase } from '../supabase-client.js'
import { badge, searchInput, setBusy, skeletonTable, toast } from '../ui/components.js'
import { clear, el, field } from '../ui/dom.js'
import { formatAddisDate, formatAddisTime } from '../utils/time.js'

const STATUS_TONE = {
  new: 'warning',
  reviewed: 'info',
  resolved: 'success',
}

export async function renderFeedback(outlet) {
  clear(outlet)
  const error = el('p', { class: 'error', role: 'alert', hidden: true })
  const tableHost = el('div', { class: 'table-wrap' })
  const kindBar = el('div', { class: 'filter-pills', role: 'group' })
  const statusBar = el('div', { class: 'filter-pills', role: 'group' })

  let items = []
  let query = ''
  let kindFilter = 'all'
  let statusFilter = 'all'

  const drawFilters = () => {
    kindBar.replaceChildren(...['all', 'feedback', 'complaint'].map((k) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: k === 'all' ? t('allFilter') : t(`kind_${k}`),
      'aria-pressed': kindFilter === k ? 'true' : 'false',
      onclick: () => {
        kindFilter = k
        drawFilters()
        draw()
      },
    })))
    statusBar.replaceChildren(...['all', 'new', 'reviewed', 'resolved'].map((s) => el('button', {
      type: 'button',
      class: 'pill-btn',
      text: s === 'all' ? t('allFilter') : t(`fb_${s}`),
      'aria-pressed': statusFilter === s ? 'true' : 'false',
      onclick: () => {
        statusFilter = s
        drawFilters()
        draw()
      },
    })))
  }

  const openRespond = (item) => {
    const dialog = el('dialog', { class: 'modal modal-wide' })
    const statusSel = el('select')
    for (const s of ['new', 'reviewed', 'resolved']) {
      statusSel.append(el('option', { value: s, text: t(`fb_${s}`) }))
    }
    statusSel.value = item.status
    const respInput = el('textarea', { maxlength: '600' })
    respInput.value = item.admin_response ?? ''

    const saveBtn = el('button', { type: 'submit', text: t('saveChanges') })
    const closeBtn = el('button', {
      type: 'button',
      class: 'secondary',
      text: t('close'),
      onclick: () => dialog.close(),
    })

    const form = el('form', {}, [
      el('h3', { text: t(`kind_${item.type}`) }),
      item.rating ? el('p', { class: 'stars', text: '★'.repeat(item.rating) + '☆'.repeat(5 - item.rating) }) : null,
      el('p', { text: item.comment }),
      field(t('status'), statusSel),
      field(t('adminResponse'), respInput),
      el('div', { class: 'modal-actions' }, [closeBtn, saveBtn]),
    ])

    form.addEventListener('submit', async (ev) => {
      ev.preventDefault()
      setBusy(saveBtn, true, t('saveChanges'))
      const payload = {
        status: statusSel.value,
        admin_response: respInput.value.trim() || null,
      }
      const { error: upErr } = await supabase
        .from('feedback')
        .update(payload)
        .eq('id', item.id)
      setBusy(saveBtn, false, t('saveChanges'))
      if (upErr) {
        toast(t('feedbackUpdateFailed'), 'error')
        return
      }
      Object.assign(item, payload)
      toast(t('feedbackUpdated'), 'success')
      dialog.close()
      draw()
    })

    dialog.append(form)
    dialog.addEventListener('close', () => dialog.remove())
    document.body.append(dialog)
    dialog.showModal()
  }

  const draw = () => {
    const filtered = items.filter((item) => {
      if (kindFilter !== 'all' && item.type !== kindFilter) return false
      if (statusFilter !== 'all' && item.status !== statusFilter) return false
      if (!query) return true
      return `${item.comment} ${item.admin_response ?? ''} ${item.type}`.toLowerCase().includes(query)
    })
    if (items.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
      return
    }
    if (filtered.length === 0) {
      tableHost.replaceChildren(el('p', { class: 'state', text: t('noMatches') }))
      return
    }
    const body = el('tbody')
    for (const item of filtered) {
      const when = `${formatAddisDate(item.created_at)} · ${formatAddisTime(item.created_at)}`
      const stars = item.rating ? '★'.repeat(item.rating) + '☆'.repeat(5 - item.rating) : '—'
      body.append(el('tr', {}, [
        el('td', {}, [badge(t(`kind_${item.type}`), item.type === 'complaint' ? 'danger' : 'info', 'feedback')]),
        el('td', { class: 'stars', text: stars }),
        el('td', { text: item.comment }),
        el('td', { class: 'mono', text: when }),
        el('td', {}, [badge(t(`fb_${item.status}`), STATUS_TONE[item.status] ?? 'neutral', 'check')]),
        el('td', { class: 'cell-end' }, [
          el('button', {
            type: 'button',
            class: 'secondary btn-sm',
            text: t('adminResponse'),
            onclick: () => openRespond(item),
          }),
        ]),
      ]))
    }
    tableHost.replaceChildren(el('table', {}, [
      el('thead', {}, [el('tr', {}, [
        el('th', { text: t('feedback') }),
        el('th', { text: t('rating') }),
        el('th', { text: t('comment') }),
        el('th', { text: t('expected') }),
        el('th', { text: t('status') }),
        el('th', { text: t('actions') }),
      ])]),
      body,
    ]))
  }

  drawFilters()
  outlet.append(
    el('header', { class: 'page-head' }, [
      el('h1', { text: t('feedback') }),
      el('p', { class: 'muted', text: t('feedbackHelp') }),
    ]),
    error,
    el('section', { class: 'panel' }, [
      el('div', { class: 'list-toolbar' }, [
        searchInput({
          placeholder: t('searchPlaceholder'),
          onInput: (val) => {
            query = val
            draw()
          },
        }),
        kindBar,
        statusBar,
      ]),
      tableHost,
    ]),
  )

  tableHost.replaceChildren(skeletonTable(5))
  const { data, error: loadErr } = await supabase
    .from('feedback')
    .select('id, type, rating, comment, status, admin_response, created_at')
    .order('created_at', { ascending: false })
    .limit(200)
  if (loadErr) {
    error.hidden = false
    error.textContent = t('setupBody')
    tableHost.replaceChildren(el('p', { class: 'state', text: t('empty') }))
    return
  }
  items = data ?? []
  draw()
}
