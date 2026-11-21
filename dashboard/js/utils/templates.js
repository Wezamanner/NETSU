import { formatAddisDate, formatAddisTime } from './time.js'

// REVIEW: native speaker — Amharic and Afaan Oromo templates are drafts.
export function previewResidentMessage({ type = 'day_before', locale = 'en', expectedStartIso }) {
  const time = expectedStartIso ? formatAddisTime(expectedStartIso) : '—'
  const date = expectedStartIso ? formatAddisDate(expectedStartIso) : '—'
  const dateTime = expectedStartIso ? `${date} ${time}` : '—'
  const lang = locale === 'am' || locale === 'om' ? locale : 'en'

  if (type === 'same_day') {
    if (lang === 'am') return `ማስታወሻ፡ በአካባቢዎ የቆሻሻ መሰብሰብ ዛሬ በ ${time} ተይዟል። እባክዎ የቤት ቆሻሻዎን ወደ ተፈቀደው መሰብሰቢያ ቦታ ያምጡ።`
    if (lang === 'om') return `Yaadachiisa: Walitti qabuun xurii naannoo keessanitti har’a sa’aatii ${time} irratti karoorfameera. Maaloo xurii mana keessaa gara bakka eeyyamameetti fidaa.`
    return `Reminder: Garbage collection in your area is scheduled for today at ${time}. Please bring your household garbage to the approved collection point.`
  }
  if (type === 'reschedule') {
    if (lang === 'am') return `ማሻሻያ፡ የአካባቢዎ ቆሻሻ መሰብሰብ ወደ ${dateTime} ተቀይሯል።`
    if (lang === 'om') return `Fooyya’iinsa: Walitti qabuun xurii naannoo keessanii gara ${dateTime} tti jijjiirameera.`
    return `Update: Your area's garbage collection has been rescheduled to ${dateTime}.`
  }
  if (type === 'cancellation') {
    if (lang === 'am') return `ማሳወቂያ፡ ለ ${date} የታቀደው የቆሻሻ መሰብሰብ ተሰርዟል። ማዘጋጃ ቤቱ ሲረጋገጥ ምትክ መርሐግብር ያሳውቃል።`
    if (lang === 'om') return `Beeksisa: Walitti qabuun xurii guyyaa ${date} karoorfame haqameera. Bulchiinsi magaalaa yeroo mirkanaa’u sagantaa bakka bu’u ni beeksisa.`
    return `Notice: The planned garbage collection for ${date} has been cancelled. The municipality will share the replacement schedule when confirmed.`
  }
  if (lang === 'am') return `የጅማ ቆሻሻ አስተዳደር፡ በአካባቢዎ የቤት ቆሻሻ መሰብሰብ ነገ በ ${time} ተይዟል። እባክዎ ቆሻሻዎን አዘጋጅተው መኪናው ከመድረሱ በፊት በተፈቀደው መሰብሰቢያ ቦታ ያስቀምጡ።`
  if (lang === 'om') return `Bulchiinsa Xurii Jimmaa: Walitti qabuun xurii mana keessaa naannoo keessanitti boru sa’aatii ${time} irratti karoorfameera. Maaloo xurii qopheessaa bakka eeyyamametti kaa’aa.`
  return `Jimma Waste Management: Household garbage collection in your area is scheduled for tomorrow, ${time}. Please prepare your household garbage and place it at the approved collection point before the truck arrives.`
}

export function dedupKey({ scheduleId, version, type, recipientId, channel }) {
  return `${scheduleId}:v${version}:${type}:${recipientId}:${channel}`
}
