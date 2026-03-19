# Symphony Infra (multi-project)

Этот набор файлов поднимает рабочую инфраструктуру Symphony для нескольких ваших проектов.

## Что входит

- `infra/build_symphony.sh` - сборка бинаря Symphony (`elixir/bin/symphony`)
- `infra/bootstrap_project.sh` - генерация `.symphony/*` в целевом проекте

## 1) Сборка Symphony

```bash
cd /Users/dmitrii/Documents/1-Projects/symphony
./infra/build_symphony.sh
```

Ожидаемый результат: есть исполняемый файл
`/Users/dmitrii/Documents/1-Projects/symphony/elixir/bin/symphony`.

## 2) Подключение проекта

Для каждого проекта выполните:

```bash
/Users/dmitrii/Documents/1-Projects/symphony/infra/bootstrap_project.sh \
  --project-root /ABS/PATH/TO/YOUR_PROJECT \
  --project-slug YOUR_LINEAR_PROJECT_SLUG \
  --repo-url git@github.com:ORG/REPO.git
```

Скрипт создаст в проекте:

- `.symphony/WORKFLOW.md`
- `.symphony/.env.example`
- `.symphony/run-symphony.sh`

## 3) Заполнение секретов/переменных

```bash
cd /ABS/PATH/TO/YOUR_PROJECT
cp .symphony/.env.example .symphony/.env
```

Заполните `.symphony/.env`:

- `LINEAR_API_KEY` - ваш ключ Linear
- `SYMPHONY_SOURCE_REPO_URL` - URL репозитория проекта
- `SYMPHONY_BIN` - путь к бинарю Symphony

Пример:

```bash
LINEAR_API_KEY=YOUR_LINEAR_API_KEY
SYMPHONY_SOURCE_REPO_URL=git@github.com:ORG/REPO.git
SYMPHONY_BIN=/Users/dmitrii/Documents/1-Projects/symphony/elixir/bin/symphony
SYMPHONY_LOGS_ROOT=/ABS/PATH/TO/YOUR_PROJECT/.symphony/log
SYMPHONY_DASHBOARD_PORT=4101
```

## 4) Запуск

```bash
cd /ABS/PATH/TO/YOUR_PROJECT
.symphony/run-symphony.sh
```

Если задан `SYMPHONY_DASHBOARD_PORT`, дашборд будет доступен на:

- `http://127.0.0.1:<PORT>/`
- API: `http://127.0.0.1:<PORT>/api/v1/state`

## 5) Как это работает

1. Symphony опрашивает Linear по вашему `LINEAR_API_KEY`.
2. Берет задачи из состояний `Todo/In Progress/Merging/Rework`.
3. Для каждого тикета создает отдельный workspace.
4. В workspace запускает `codex app-server`.
5. Агент выполняет работу в рамках `WORKFLOW.md`.

## 6) Что проверить, если не стартует

1. Есть ли `mix` и собран ли бинарь (`infra/build_symphony.sh`).
2. Установлен ли `codex` и доступен ли в `PATH`.
3. Корректны ли `LINEAR_API_KEY` и `YOUR_LINEAR_PROJECT_SLUG`.
4. Доступен ли `SYMPHONY_SOURCE_REPO_URL` для `git clone`.
