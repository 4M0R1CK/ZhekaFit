const url = process.env.SUPABASE_URL?.replace(/\/$/, '')
const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY

if (!url || !key) throw new Error('Set SUPABASE_URL and SUPABASE_SECRET_KEY before seeding content.')

async function rest(path, { method = 'GET', body, prefer } = {}) {
  const headers = { apikey: key, 'Content-Type': 'application/json' }
  if (prefer) headers.Prefer = prefer
  const response = await fetch(`${url}/rest/v1/${path}`, {
    method,
    headers,
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  })
  const text = await response.text()
  if (!response.ok) throw new Error(`Supabase REST ${method} ${path}: HTTP ${response.status} ${text}`)
  return text ? JSON.parse(text) : null
}

const programs = [
  { slug:'strength-foundation', title:'Силовая база', category:'strength', level:'beginner', duration_minutes:50, description:'Тренировки с базовыми движениями, постепенным увеличением нагрузки и вниманием к технике.', audience:'Для тех, кто начинает силовые тренировки или возвращается после перерыва.', equipment:['Свободные веса','Тренажёры'], recommended_frequency:'2–3 раза в неделю', image_path:'site/strength.jpg', is_published:true, sort_order:10 },
  { slug:'cardio-endurance', title:'Кардио и выносливость', category:'cardio', level:'all', duration_minutes:40, description:'Равномерная кардионагрузка с вариантами интенсивности и контролем темпа.', audience:'Для развития общей выносливости и поддержания активности.', equipment:['Беговая дорожка','Велотренажёр'], recommended_frequency:'2–4 раза в неделю', image_path:'site/cardio.jpg', is_published:true, sort_order:20 },
  { slug:'functional-movement', title:'Функциональное движение', category:'functional', level:'intermediate', duration_minutes:45, description:'Круговая работа над силой, координацией и устойчивостью в движении.', audience:'Для тех, кто хочет разнообразить силовые и кардио занятия.', equipment:['Гантели','Коврик','Медбол'], recommended_frequency:'2–3 раза в неделю', image_path:'site/training.jpg', is_published:true, sort_order:30 },
  { slug:'mobility-recovery', title:'Мобильность и восстановление', category:'recovery', level:'all', duration_minutes:45, description:'Спокойная работа над подвижностью суставов, балансом и восстановлением.', audience:'Подходит как самостоятельное занятие и как дополнение к силовым тренировкам.', equipment:['Коврик','Ремень для растяжки'], recommended_frequency:'1–3 раза в неделю', image_path:'site/yoga.jpg', is_published:true, sort_order:40 },
  { slug:'group-circuit', title:'Круговая тренировка', category:'group', level:'all', duration_minutes:45, description:'Групповое занятие с чередованием силовых и аэробных интервалов.', audience:'Для участников с разным уровнем подготовки: тренер предлагает варианты нагрузки.', equipment:['Коврик','Гантели'], recommended_frequency:'1–3 раза в неделю', image_path:'site/group.jpg', is_published:true, sort_order:50 },
  { slug:'strength-progress', title:'Силовой прогресс', category:'strength', level:'advanced', duration_minutes:60, description:'Планомерная силовая работа с акцентом на технику и постепенную прогрессию.', audience:'Для участников с опытом силовых тренировок.', equipment:['Штанга','Стойка','Свободные веса'], recommended_frequency:'2–3 раза в неделю', image_path:'site/gym.jpg', is_published:true, sort_order:60 },
]

const trainers = [
  { slug:'strength-team', full_name:'Команда силовой подготовки', specialization:'Силовые тренировки', experience_years:null, bio:'Тренеры помогают подобрать рабочую нагрузку, освоить технику упражнений и выстроить регулярный план.', photo_path:'site/trainer.jpg', is_published:true, sort_order:10 },
  { slug:'group-team', full_name:'Команда групповых программ', specialization:'Групповые и функциональные тренировки', experience_years:null, bio:'Команда проводит групповые занятия и предлагает варианты упражнений с учётом уровня подготовки.', photo_path:'site/group.jpg', is_published:true, sort_order:20 },
  { slug:'recovery-team', full_name:'Команда восстановления', specialization:'Мобильность и восстановление', experience_years:null, bio:'Тренеры ведут занятия на подвижность, баланс и восстановление после нагрузки.', photo_path:'site/yoga.jpg', is_published:true, sort_order:30 },
]

const plans = [
  { slug:'start', title:'START', description:'Предварительная стоимость — подтвердите её у клуба перед запуском продаж.', price_minor:390000, currency:'RUB', duration_days:30, features:['Тренажёрный зал','Вводная консультация','Кардио-зона'], is_published:true, sort_order:10 },
  { slug:'unlimited', title:'UNLIMITED', description:'Предварительная стоимость — подтвердите её у клуба перед запуском продаж.', price_minor:590000, currency:'RUB', duration_days:30, features:['Тренажёрный зал','Групповые занятия','Полное расписание','Вводная консультация'], is_published:true, sort_order:20 },
  { slug:'personal', title:'PERSONAL', description:'Предварительная стоимость — подтвердите её у клуба перед запуском продаж.', price_minor:990000, currency:'RUB', duration_days:30, features:['Все возможности UNLIMITED','Персональные занятия','Приоритетная запись'], is_published:true, sort_order:30 },
]

const programRows = await rest('programs?on_conflict=slug', { method:'POST', body:programs, prefer:'resolution=merge-duplicates,return=representation' })
const trainerRows = await rest('trainers?on_conflict=slug', { method:'POST', body:trainers, prefer:'resolution=merge-duplicates,return=representation' })
const planRows = await rest('membership_plans?on_conflict=slug', { method:'POST', body:plans, prefer:'resolution=merge-duplicates,return=representation' })
const programIds = new Map(programRows.map(row => [row.slug,row.id]))
const trainerIds = new Map(trainerRows.map(row => [row.slug,row.id]))

const links = [
  ['strength-foundation','strength-team'],['strength-progress','strength-team'],
  ['cardio-endurance','group-team'],['functional-movement','group-team'],
  ['group-circuit','group-team'],['mobility-recovery','recovery-team'],
].map(([program,trainer]) => ({ program_id:programIds.get(program), trainer_id:trainerIds.get(trainer) }))
await rest('program_trainers?on_conflict=program_id%2Ctrainer_id', { method:'POST', body:links, prefer:'resolution=merge-duplicates,return=minimal' })

const now = new Date()
const existingQuery = new URLSearchParams({ select:'program_id,trainer_id,starts_at', starts_at:`gte.${now.toISOString()}`, limit:'1000' })
const existing = await rest(`class_sessions?${existingQuery}`)
const existingKeys = new Set(existing.map(row => `${row.program_id}|${row.trainer_id}|${new Date(row.starts_at).toISOString()}`))
const schedule = [
  ['08:00','strength-foundation','strength-team','Зал 1'],
  ['13:00','cardio-endurance','group-team','Кардио-зона'],
  ['19:00','functional-movement','group-team','Зал 1'],
  ['20:00','mobility-recovery','recovery-team','Зал 2'],
]
const localDate = new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Novosibirsk',year:'numeric',month:'2-digit',day:'2-digit'}).format(now)
const [year,month,day] = localDate.split('-').map(Number)
const sessions = []
for (let offset=0; offset<7; offset++) {
  const date = new Date(Date.UTC(year,month-1,day+offset)).toISOString().slice(0,10)
  for (const [time,programSlug,trainerSlug,room] of schedule) {
    const startsAt = new Date(`${date}T${time}:00+07:00`)
    const programId = programIds.get(programSlug)
    const trainerId = trainerIds.get(trainerSlug)
    const key = `${programId}|${trainerId}|${startsAt.toISOString()}`
    if (startsAt > now && !existingKeys.has(key)) {
      sessions.push({ program_id:programId, trainer_id:trainerId, starts_at:startsAt.toISOString(), duration_minutes:programRows.find(row=>row.id===programId).duration_minutes, capacity:12, room, status:'scheduled' })
      existingKeys.add(key)
    }
  }
}
if (sessions.length) await rest('class_sessions', { method:'POST', body:sessions, prefer:'return=minimal' })

console.log(`Published ${programRows.length} programs, ${trainerRows.length} trainer teams, ${planRows.length} plans; added ${sessions.length} future sessions.`)
console.log('Plan prices are provisional and should be replaced with club-approved amounts.')
