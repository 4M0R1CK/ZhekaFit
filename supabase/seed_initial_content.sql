-- Initial editable club content for ZhekaFitness.
-- Trainer labels are team roles, not invented people. Review proposed plan prices
-- and replace them with the club's approved prices before publishing the pricing page.
-- Safe to rerun: records are matched by slug and sessions by their scheduled time.

begin;

insert into public.programs
  (slug,title,category,level,duration_minutes,description,audience,equipment,recommended_frequency,image_path,is_published,sort_order)
values
  ('strength-foundation','Силовая база','strength','beginner',50,'Тренировки с базовыми движениями, постепенным увеличением нагрузки и вниманием к технике.','Для тех, кто начинает силовые тренировки или возвращается после перерыва.',array['Свободные веса','Тренажёры'],'2–3 раза в неделю','site/strength.jpg',true,10),
  ('cardio-endurance','Кардио и выносливость','cardio','all',40,'Равномерная кардионагрузка с вариантами интенсивности и контролем темпа.','Для развития общей выносливости и поддержания активности.',array['Беговая дорожка','Велотренажёр'],'2–4 раза в неделю','site/cardio.jpg',true,20),
  ('functional-movement','Функциональное движение','functional','intermediate',45,'Круговая работа над силой, координацией и устойчивостью в движении.','Для тех, кто хочет разнообразить силовые и кардио занятия.',array['Гантели','Коврик','Медбол'],'2–3 раза в неделю','site/training.jpg',true,30),
  ('mobility-recovery','Мобильность и восстановление','recovery','all',45,'Спокойная работа над подвижностью суставов, балансом и восстановлением.','Подходит как самостоятельное занятие и как дополнение к силовым тренировкам.',array['Коврик','Ремень для растяжки'],'1–3 раза в неделю','site/yoga.jpg',true,40),
  ('group-circuit','Круговая тренировка','group','all',45,'Групповое занятие с чередованием силовых и аэробных интервалов.','Для участников с разным уровнем подготовки: тренер предлагает варианты нагрузки.',array['Коврик','Гантели'],'1–3 раза в неделю','site/group.jpg',true,50),
  ('strength-progress','Силовой прогресс','strength','advanced',60,'Планомерная силовая работа с акцентом на технику и постепенную прогрессию.','Для участников с опытом силовых тренировок.',array['Штанга','Стойка','Свободные веса'],'2–3 раза в неделю','site/gym.jpg',true,60)
on conflict(slug) do update set
  title=excluded.title, category=excluded.category, level=excluded.level,
  duration_minutes=excluded.duration_minutes, description=excluded.description,
  audience=excluded.audience, equipment=excluded.equipment,
  recommended_frequency=excluded.recommended_frequency, image_path=excluded.image_path,
  is_published=excluded.is_published, sort_order=excluded.sort_order;

insert into public.trainers
  (slug,full_name,specialization,experience_years,bio,photo_path,is_published,sort_order)
values
  ('strength-team','Команда силовой подготовки','Силовые тренировки',null,'Тренеры помогают подобрать рабочую нагрузку, освоить технику упражнений и выстроить регулярный план.', 'site/trainer.jpg',true,10),
  ('group-team','Команда групповых программ','Групповые и функциональные тренировки',null,'Команда проводит групповые занятия и предлагает варианты упражнений с учётом уровня подготовки.', 'site/group.jpg',true,20),
  ('recovery-team','Команда восстановления','Мобильность и восстановление',null,'Тренеры ведут занятия на подвижность, баланс и восстановление после нагрузки.', 'site/yoga.jpg',true,30)
on conflict(slug) do update set
  full_name=excluded.full_name, specialization=excluded.specialization,
  experience_years=excluded.experience_years, bio=excluded.bio,
  photo_path=excluded.photo_path, is_published=excluded.is_published, sort_order=excluded.sort_order;

insert into public.program_trainers(program_id,trainer_id)
select p.id,t.id from (values
  ('strength-foundation','strength-team'),('strength-progress','strength-team'),
  ('cardio-endurance','group-team'),('functional-movement','group-team'),
  ('group-circuit','group-team'),('mobility-recovery','recovery-team')
) as links(program_slug,trainer_slug)
join public.programs p on p.slug=links.program_slug
join public.trainers t on t.slug=links.trainer_slug
on conflict(program_id,trainer_id) do nothing;

insert into public.membership_plans
  (slug,title,description,price_minor,currency,duration_days,features,is_published,sort_order)
values
  ('start','START','Предварительная стоимость — подтвердите её у клуба перед запуском продаж.',390000,'RUB',30,'["Тренажёрный зал","Вводная консультация","Кардио-зона"]'::jsonb,true,10),
  ('unlimited','UNLIMITED','Предварительная стоимость — подтвердите её у клуба перед запуском продаж.',590000,'RUB',30,'["Тренажёрный зал","Групповые занятия","Полное расписание","Вводная консультация"]'::jsonb,true,20),
  ('personal','PERSONAL','Предварительная стоимость — подтвердите её у клуба перед запуском продаж.',990000,'RUB',30,'["Все возможности UNLIMITED","Персональные занятия","Приоритетная запись"]'::jsonb,true,30)
on conflict(slug) do update set
  title=excluded.title, description=excluded.description, price_minor=excluded.price_minor,
  currency=excluded.currency, duration_days=excluded.duration_days,
  features=excluded.features, is_published=excluded.is_published, sort_order=excluded.sort_order;

with slots as (
  select * from (values
    ('08:00'::time,'strength-foundation','strength-team','Зал 1'),
    ('13:00'::time,'cardio-endurance','group-team','Кардио-зона'),
    ('19:00'::time,'functional-movement','group-team','Зал 1'),
    ('20:00'::time,'mobility-recovery','recovery-team','Зал 2')
  ) as v(start_time,program_slug,trainer_slug,room)
), days as (
  select (current_date + n)::date as session_day from generate_series(0,6) as g(n)
)
insert into public.class_sessions(program_id,trainer_id,starts_at,duration_minutes,capacity,room,status)
select p.id,t.id,((d.session_day + s.start_time) at time zone 'Asia/Novosibirsk'),p.duration_minutes,12,s.room,'scheduled'
from days d cross join slots s
join public.programs p on p.slug=s.program_slug
join public.trainers t on t.slug=s.trainer_slug
where ((d.session_day + s.start_time) at time zone 'Asia/Novosibirsk') > now()
  and not exists (
    select 1 from public.class_sessions existing
    where existing.program_id=p.id and existing.trainer_id=t.id
      and existing.starts_at=((d.session_day + s.start_time) at time zone 'Asia/Novosibirsk')
  );

commit;
