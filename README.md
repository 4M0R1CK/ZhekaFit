# ZhekaFitness

Веб-приложение фитнес-клуба на React, TypeScript и Vite. Авторизация, профиль, каталог, тарифы, расписание, записи и история подключены к Supabase. Демо-аккаунтов, вымышленных тарифов и локального сохранения пользовательских данных нет.

## Запуск

Требуется Node.js 20.19+ или 22.12+.

```powershell
npm install
npm run dev
```

Для production-сборки:

```powershell
npm run build
npm run preview
```

Проверки:

```powershell
npm run lint
npm run test
```

## Подключение Supabase

1. Скопируй `.env.example` в `.env.local` и заполни URL проекта и publishable key из Supabase. `.env.local` исключён из Git.
2. В Supabase Dashboard открой **SQL Editor** и выполни [`supabase/create_database.sql`](supabase/create_database.sql). Скрипт рассчитан на повторный запуск, исправляет недостающие таблицы/колонки, включает RLS, создаёт функции бронирования и доступности мест, bucket `club-media` и политики Storage. Он не добавляет пользователей, программы, занятия или тарифы.
3. В **Authentication → URL Configuration** укажи адрес сайта и разрешённые redirect URL, например `http://localhost:5173/**` и production URL. В **Authentication → Providers** включи Email. Вход и регистрация используют Supabase Auth; если включено подтверждение email, пользователь входит после перехода по ссылке из письма.
4. Добавляй и публикуй реальные программы, тренеров, расписание и тарифы в Supabase. Публичные страницы показывают только строки с `is_published = true`; пустые таблицы отображаются как пустые состояния.

Структура данных и правила доступа описаны в [`supabase/README.md`](supabase/README.md). SQL-файл миграции [`supabase/migrations/202611130001_initial_schema.sql`](supabase/migrations/202611130001_initial_schema.sql) синхронизирован со скриптом для SQL Editor. Для проекта, где SQL уже запускался вручную, повторно запускай repair-скрипт из SQL Editor, не делай `db push` с неизвестной историей миграций.

## Docker и GitHub Actions

Production-образ собирает статическую версию Vite и раздаёт её через Nginx. В Docker передаются только публичные настройки Supabase для браузера; секретный ключ Supabase не нужен и не должен передаваться в сборку.

Для локальной сборки задай значения из `.env.local` в PowerShell и собери образ:

```powershell
$env:VITE_SUPABASE_URL = "https://<project-ref>.supabase.co"
$env:VITE_SUPABASE_PUBLISHABLE_KEY = "<publishable-key>"
docker build --build-arg VITE_SUPABASE_URL --build-arg VITE_SUPABASE_PUBLISHABLE_KEY -t zhekafitness:local .
```

Запусти контейнер и открой сайт на `http://localhost:8080`:

```powershell
docker run --name zhekafitness -d -p 8080:8080 zhekafitness:local
docker ps
docker stop zhekafitness
docker rm zhekafitness
```

Опубликованный в GHCR образ можно скачать и запустить так:

```powershell
docker pull ghcr.io/4m0r1ck/zhekafit:latest
docker run --name zhekafitness -d -p 8080:8080 ghcr.io/4m0r1ck/zhekafit:latest
```

Workflow `.github/workflows/ci.yml` запускает `npm ci`, lint, тесты и production-сборку для каждого push в `main` и pull request в `main`. После успешной проверки push в `main` собирает Docker-образ и публикует его в GitHub Container Registry под тегами `latest` и SHA коммита.

Чтобы опубликованный сайт подключался к Supabase, в настройках репозитория добавь в **Settings → Secrets and variables → Actions → Variables** переменные `VITE_SUPABASE_URL` и `VITE_SUPABASE_PUBLISHABLE_KEY`. Это публичные клиентские настройки, которые Vite встраивает в браузерный код. Workflow завершит публикацию с ошибкой, если переменные не заданы. При необходимости сделай созданный пакет `ghcr.io/4m0r1ck/zhekafit` публичным в **Packages → Package settings → Change visibility**.

### Pull request

1. Создай ветку, например `feature/<короткое-название>`, и внеси изменения в ней.
2. Отправь ветку на GitHub командой `git push -u origin feature/<короткое-название>`.
3. Открой pull request из этой ветки в `main`. GitHub Actions автоматически выполнит lint, тесты и сборку.
4. Проверь результат во вкладке **Actions** и исправь ошибки до слияния.
5. После ревью слей pull request в `main`. Это запустит сборку и публикацию образа в GHCR.

## Изображения

Storage bucket `club-media` создаётся SQL-скриптом. Для загрузки файлов клуба положи JPEG, PNG, WebP или AVIF в `supabase/assets/upload` и запусти:

```powershell
$env:SUPABASE_URL = "https://<project-ref>.supabase.co"
$env:SUPABASE_SECRET_KEY = "<secret-key>"
npm run supabase:upload-assets
```

Скрипт загружает файлы в `club-media/site/`, сохраняет вложенные папки, использует upsert и ограничивает размер файла 10 MB. Для фотографий главной нужны имена `gym.jpg`, `club.jpg` и `training.jpg`; остальные изображения используются в карточках программ и тренерских команд. Начальный набор уже загружен в Storage.

`npm run supabase:seed-content` безопасно повторно добавляет/обновляет стартовый контент и создаёт расписание на ближайшие 7 дней. В базе сейчас 6 программ, 3 тренерские команды, 3 тарифа и 24 будущих занятия. Цены тарифов в стартовом наборе предварительные — замени их на утверждённые клубом в `membership_plans` перед продажами. SQL-вариант начального набора доступен в [`supabase/seed_initial_content.sql`](supabase/seed_initial_content.sql).

Для загрузчика нужен только серверный `SUPABASE_SECRET_KEY` (либо legacy `SUPABASE_SERVICE_ROLE_KEY`). Никогда не записывай этот ключ в `.env.local` как `VITE_*`, frontend-код, Git или опубликованные логи. В браузере используется только publishable key; загрузка фото профиля ограничена пользовательской папкой `profiles/<auth-user-id>/` политиками Storage.

Папка `supabase/assets/upload` намеренно не содержит изображений-заглушек. Помести туда реальные материалы клуба перед запуском загрузчика.

## Реальные ограничения

- Сайт не показывает каталог, расписание или тарифы, пока соответствующие данные не добавлены и не опубликованы администратором.
- Оплата абонементов не подключена: форма создаёт заявку со статусом `pending` в Supabase.
- Посещения и отметки `attended` / `no_show` должны вноситься администратором; клиент их не выдумывает.
- Контакты клуба должны быть добавлены перед публикацией.
