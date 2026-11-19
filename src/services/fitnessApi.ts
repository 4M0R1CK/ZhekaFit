import { supabase } from '../lib/supabase'

export type Program = { id: string; dbId: string; title: string; category: string; level: string; duration: string; desc: string; image: string; description: string; audience: string; equipment: string[]; frequency: string }
export type Trainer = { id: string; dbId: string; name: string; specialty: string; experience: string; image: string; bio: string }
export type Plan = { id: string; slug: string; price: string; term: string; features: string[]; note: string }
export type Session = { id: string; day: string; date: string; time: string; title: string; trainer: string; category: string; duration: string; seats: number }
const categories: Record<string,string> = { strength:'Силовые', cardio:'Кардио', functional:'Функциональные', recovery:'Восстановительные', group:'Групповые' }
const levels: Record<string,string> = { beginner:'Начальный', intermediate:'Средний', advanced:'Продвинутый', all:'Любой' }
const imageUrl = (path?: string | null) => path ? (path.startsWith('http') ? path : supabase.storage.from('club-media').getPublicUrl(path).data.publicUrl) : ''
export const getClubImage = (path: string) => imageUrl(path)

export async function getPrograms(): Promise<Program[]> {
  const { data, error } = await supabase.from('programs').select('*').eq('is_published', true).order('sort_order').order('title')
  if (error) throw error
  return (data ?? []).map((p) => ({ id:p.slug, dbId:p.id, title:p.title, category:categories[p.category] ?? p.category, level:levels[p.level] ?? p.level, duration:`${p.duration_minutes} мин`, desc:p.description, image:imageUrl(p.image_path), description:p.description, audience:p.audience, equipment:p.equipment ?? [], frequency:p.recommended_frequency ?? '' }))
}
export async function getTrainers(): Promise<Trainer[]> {
  const { data, error } = await supabase.from('trainers').select('*').eq('is_published', true).order('sort_order').order('full_name')
  if (error) throw error
  return (data ?? []).map((t) => ({ id:t.slug, dbId:t.id, name:t.full_name, specialty:t.specialization, experience:t.experience_years == null ? '' : `${t.experience_years} лет практики`, image:imageUrl(t.photo_path), bio:t.bio }))
}
export async function getPlans(): Promise<Plan[]> {
  const { data, error } = await supabase.from('membership_plans').select('*').eq('is_published', true).order('sort_order')
  if (error) throw error
  return (data ?? []).map((p) => ({ id:p.id, slug:p.slug, price:new Intl.NumberFormat('ru-RU',{style:'currency',currency:p.currency,maximumFractionDigits:0}).format(p.price_minor/100), term:`${p.duration_days} дней`, features:Array.isArray(p.features)?p.features:[], note:p.description }))
}
export async function getSessions(): Promise<Session[]> {
  const { data, error } = await supabase.rpc('get_class_session_availability')
  if (error) throw error
  return (data ?? []).map((s: {id:string;starts_at:string;duration_minutes:number;seats_available:number;program_title:string;program_category:string;trainer_name:string}) => { const start=new Date(s.starts_at); return { id:s.id, date:s.starts_at, day:new Intl.DateTimeFormat('ru-RU',{weekday:'long',timeZone:'Asia/Novosibirsk'}).format(start).replace(/^./,c=>c.toUpperCase()), time:new Intl.DateTimeFormat('ru-RU',{hour:'2-digit',minute:'2-digit',timeZone:'Asia/Novosibirsk'}).format(start), title:s.program_title ?? '', category:categories[s.program_category] ?? s.program_category ?? '', trainer:s.trainer_name ?? '', duration:`${s.duration_minutes} мин`, seats:s.seats_available } })
}
export async function getProfile(id: string) {
  const { data, error } = await supabase.from('profiles').select('id,first_name,last_name,phone,birth_date,avatar_path,training_preferences').eq('id',id).maybeSingle()
  if (error) throw error
  return data
}
