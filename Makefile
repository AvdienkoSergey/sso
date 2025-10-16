.PHONY: help generate clean install-tools pr-view release-view repo-view check-gh check-protoc check-deps
.PHONY: test lint fmt vet build pre-commit
.PHONY: branch-feature branch-fix branch-hotfix branch-chore help-branch

# Определяем GitHub username и repo из git remote
GITHUB_USER := $(shell git remote get-url origin | sed -n 's/.*github.com[:/]\(.*\)\/.*\.git/\1/p' || echo "")
GITHUB_REPO := $(shell git remote get-url origin | sed -n 's/.*github.com[:/].*\/\(.*\)\.git/\1/p' || echo "")

# Определяем операционную систему
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	OS := linux
endif
ifeq ($(UNAME_S),Darwin)
	OS := macos
endif
ifeq ($(findstring MINGW,$(UNAME_S)),MINGW)
	OS := windows
endif
ifeq ($(findstring MSYS,$(UNAME_S)),MSYS)
	OS := windows
endif

# Цвета для вывода
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Версии инструментов
GOLANGCI_LINT_VERSION := v1.64.0
MOCKGEN_VERSION := latest

# Получить текущую ветку
CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

help:
	@echo "=========================================="
	@echo "Доступные команды:"
	@echo ""
	@echo "Текущая ветка: $(CURRENT_BRANCH)"
	@echo "Система: $(OS)"
	@echo "=========================================="
	@echo ""
	@echo "$(YELLOW)Проверка окружения:$(NC)"
	@echo "  make check-deps     - Проверить все зависимости"
	@echo ""
	@echo "$(YELLOW)Разработка:$(NC)"
	@echo "  make fmt            - Форматирование кода"
	@echo "  make lint           - Запуск линтера"
	@echo "  make vet            - Статический анализ"
	@echo "  make build          - Сборка проекта"
	@echo "  make test           - Запуск тестов"
	@echo "  make pre-commit     - Все проверки перед коммитом"
	@echo ""
	@echo "$(YELLOW)Работа с комментариями в репозиторий:$(NC)"
	@echo "  make commit         - Коммит с проверками (pre-commit + add + commit)"
	@echo "  make quick-commit   - Полный workflow (pre-commit + add + commit + push)"
	@echo "  make push-current   - Push текущей ветки в origin"
	@echo ""
	@echo "$(YELLOW)Создание веток в репозитории:$(NC)"
	@echo "  make branch-feature - Создать feature/* ветку"
	@echo "  make branch-fix     - Создать fix/* ветку"
	@echo "  make branch-hotfix  - Создать hotfix/* ветку"
	@echo "  make branch-chore   - Создать chore/* ветку"
	@echo "  make help-branch    - Показать правила именования веток"
	@echo ""
	@echo "$(YELLOW)Работа с репозиторием в браузере:$(NC)"
	@echo "  make pr-view        - Открыть Pull Requests в браузере"
	@echo "  make release-view   - Открыть Releases в браузере"
	@echo "  make repo-view      - Открыть репозиторий в браузере"
	@echo "  make actions-view   - Открыть GitHub Actions в браузере"
	@echo ""

install-tools:
	@echo "$(BLUE)Установка инструментов разработки...$(NC)"
	@echo ""
	@echo "$(YELLOW)1. golangci-lint (линтер)$(NC)"
	@which golangci-lint > /dev/null 2>&1 || \
		(curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin $(GOLANGCI_LINT_VERSION))
	@echo "$(GREEN)golangci-lint установлен$(NC)"
	@echo ""
	@echo "$(YELLOW)2. mockgen (моки для тестов)$(NC)"
	@go install go.uber.org/mock/mockgen@$(MOCKGEN_VERSION)
	@echo "$(GREEN)mockgen установлен$(NC)"
	@echo ""
	@echo "$(GREEN)Все инструменты установлены!$(NC)"

# ==========================================
# Проверка всех зависимостей
# ==========================================
check-deps:
	@echo ""
	@echo "Проверка Go..."
	@if which go > /dev/null 2>&1; then \
		echo "SUCCESS. Go установлен: $$(go version)"; \
	else \
		echo "FAIL. Go НЕ установлен!"; \
		echo "Скачайте с https://go.dev/dl/"; \
		exit 1; \
	fi
	@echo ""
	@echo "Проверка make..."
	@if which make > /dev/null 2>&1; then \
		echo "SUCCESS. make установлен: $$(make --version | head -n 1)"; \
	else \
		echo "FAIL. Make НЕ установлен (но вы же его используете...)"; \
	fi
	@echo ""
	@echo "Опционально: GitHub CLI"
	@if which gh > /dev/null 2>&1; then \
		echo "SUCCESS. gh установлен: $$(gh --version | head -n 1)"; \
	else \
		echo "FAIL. gh НЕ установлен (опционально)"; \
		if [ "$(OS)" = "macos" ]; then \
			echo "  brew install gh"; \
		elif [ "$(OS)" = "linux" ]; then \
			echo "  https://github.com/cli/cli/blob/trunk/docs/install_linux.md"; \
		elif [ "$(OS)" = "windows" ]; then \
			echo "  choco install gh"; \
			echo "  или scoop install gh"; \
		fi; \
	fi
	@echo ""
	@echo "Проверка завершена!"

fmt:
	@echo "$(BLUE)Форматирование кода...$(NC)"
	@go fmt ./...
	@gofmt -s -w .
	@echo "$(GREEN)Форматирование завершено$(NC)"

lint:
	@echo "$(BLUE)Запуск линтера...$(NC)"
	@if which golangci-lint > /dev/null 2>&1; then \
		golangci-lint run ./...; \
		echo "$(GREEN)Линтер завершен$(NC)"; \
	else \
		echo "$(RED)golangci-lint не установлен!$(NC)"; \
		echo "$(YELLOW)Запустите: make install-tools$(NC)"; \
		exit 1; \
	fi

vet:
	@echo "$(BLUE)Статический анализ (go vet)...$(NC)"
	@go vet ./...
	@echo "$(GREEN)Анализ завершен$(NC)"

test:
	@echo "$(BLUE)Запуск тестов...$(NC)"
	@go test -v -race -coverprofile=coverage.out ./...
	@echo "$(GREEN)Тесты завершены$(NC)"

build:
	@echo "$(BLUE)Сборка проекта...$(NC)"
	@go build -v ./...
	@echo "$(GREEN)Сборка завершена$(NC)"

pre-commit: fmt vet lint test
	@echo ""
	@echo "$(GREEN)===============================================================$(NC)"
	@echo "$(GREEN)Все проверки пройдены! Можно делать commit.$(NC)"
	@echo "$(GREEN)===============================================================$(NC)"

# ==========================================
# Проверка наличия gh CLI
# ==========================================
check-gh:
	@which gh > /dev/null 2>&1 || (echo "FAIL. GitHub CLI не установлен. Открываю через браузер..." && exit 1)

# ==========================================
# Работа с коммитами в репозиторий
# ==========================================
commit: pre-commit
	@echo ""
	@echo "$(BLUE)Создание коммита$(NC)"
	@echo ""
	@echo "$(YELLOW)Выберите тип коммита:$(NC)"
	@echo "  1) feat     - Новая функциональность"
	@echo "  2) fix      - Исправление бага"
	@echo "  3) docs     - Изменения в документации"
	@echo "  4) style    - Форматирование, отступы (не влияет на код)"
	@echo "  5) refactor - Рефакторинг кода"
	@echo "  6) test     - Добавление или изменение тестов"
	@echo "  7) chore    - Обновление зависимостей, конфигов"
	@echo "  8) ci       - Изменения в CI/CD"
	@echo "  9) perf     - Улучшение производительности"
	@echo ""
	@read -p "Введите номер (1-9): " type_num; \
	case $$type_num in \
		1) type="feat";; \
		2) type="fix";; \
		3) type="docs";; \
		4) type="style";; \
		5) type="refactor";; \
		6) type="test";; \
		7) type="chore";; \
		8) type="ci";; \
		9) type="perf";; \
		*) echo "$(RED)Неверный выбор!$(NC)"; exit 1;; \
	esac; \
	echo ""; \
	echo "$(YELLOW)Введите описание коммита:$(NC)"; \
	read -p "> " message; \
	if [ -z "$$message" ]; then \
		echo "$(RED)Ошибка: описание не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "$(BLUE)Добавление файлов...$(NC)"; \
	git add .; \
	echo "$(BLUE)Создание коммита: $$type: $$message$(NC)"; \
	git commit -m "$$type: $$message"; \
	echo "$(GREEN)Коммит создан успешно!$(NC)"; \
	echo ""; \
	echo "$(YELLOW)Для push используйте: make push-current$(NC)"

push-current:
	@echo "$(BLUE)Push в origin/$(CURRENT_BRANCH)$(NC)"
	@if [ "$(CURRENT_BRANCH)" = "main" ] || [ "$(CURRENT_BRANCH)" = "test" ] || [ "$(CURRENT_BRANCH)" = "dev" ]; then \
		echo "$(RED)ВНИМАНИЕ: Вы пытаетесь запушить в защищенную ветку $(CURRENT_BRANCH)!$(NC)"; \
		read -p "Продолжить? (yes/no): " confirm; \
		if [ "$$confirm" != "yes" ]; then \
			echo "$(YELLOW)Push отменен$(NC)"; \
			exit 1; \
		fi; \
	fi
	@git push origin $(CURRENT_BRANCH)
	@echo "$(GREEN)Push выполнен успешно!$(NC)"

quick-commit: commit push-current
	@echo ""
	@echo "$(GREEN)===============================================================$(NC)"
	@echo "$(GREEN)Полный workflow коммита выполнен успешно!$(NC)"
	@echo "$(GREEN)Изменения запушены в origin/$(CURRENT_BRANCH)$(NC)"
	@echo "$(GREEN)===============================================================$(NC)"

# ==========================================
# Работа с репозиторием в браузере
# ==========================================
pr-view:
	@if which gh > /dev/null 2>&1; then \
		gh pr view --web 2>/dev/null || gh pr list --web; \
	else \
		echo "Открываю Pull Requests в браузере..."; \
		open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/pulls" 2>/dev/null || \
		xdg-open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/pulls" 2>/dev/null || \
		echo "Перейдите по ссылке: https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/pulls"; \
	fi

release-view:
	@if which gh > /dev/null 2>&1; then \
		gh release view --web 2>/dev/null || gh release list --web; \
	else \
		echo "Открываю Releases в браузере..."; \
		open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/releases" 2>/dev/null || \
		xdg-open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/releases" 2>/dev/null || \
		echo "Перейдите по ссылке: https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/releases"; \
	fi

repo-view:
	@if which gh > /dev/null 2>&1; then \
		gh repo view --web; \
	else \
		echo "Открываю репозиторий в браузере..."; \
		open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)" 2>/dev/null || \
		xdg-open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)" 2>/dev/null || \
		echo "Перейдите по ссылке: https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)"; \
	fi

actions-view:
	@if which gh > /dev/null 2>&1; then \
		gh workflow view release-please.yml --web 2>/dev/null || \
		echo "Открываю Actions в браузере через URL..."; \
		open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/actions" 2>/dev/null || \
		xdg-open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/actions" 2>/dev/null || \
		echo "Перейдите по ссылке: https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/actions"; \
	else \
		echo "Открываю Actions в браузере..."; \
		open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/actions" 2>/dev/null || \
		xdg-open "https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/actions" 2>/dev/null || \
		echo "Перейдите по ссылке: https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/actions"; \
	fi

# ==========================================
# Работа с ветками (чтобы не было больно при PR, так как имя ветки валидируется и проходит через Rules)
# ==========================================
branch-feature:
	@echo "$(BLUE)Создание feature ветки$(NC)"
	@read -p "Feature name (e.g., 'add-oauth'): " name; \
	if [ -z "$$name" ]; then \
		echo "$(RED)Ошибка: имя ветки не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	git checkout -b feature/$$name && \
	echo "$(GREEN)Создана ветка: feature/$$name$(NC)"

branch-fix:
	@echo "$(BLUE)Создание fix ветки$(NC)"
	@read -p "Fix name (e.g., 'login-error'): " name; \
	if [ -z "$$name" ]; then \
		echo "$(RED)Ошибка: имя ветки не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	git checkout -b fix/$$name && \
	echo "$(GREEN)Создана ветка: fix/$$name$(NC)"

branch-hotfix:
	@echo "$(BLUE)Создание hotfix ветки$(NC)"
	@read -p "Hotfix name (e.g., 'security-patch'): " name; \
	if [ -z "$$name" ]; then \
		echo "$(RED)Ошибка: имя ветки не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	git checkout -b hotfix/$$name && \
	echo "$(GREEN)Создана ветка: hotfix/$$name$(NC)"

branch-chore:
	@echo "$(BLUE)Создание chore ветки$(NC)"
	@read -p "Chore name (e.g., 'update-deps'): " name; \
	if [ -z "$$name" ]; then \
		echo "$(RED)Ошибка: имя ветки не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	git checkout -b chore/$$name && \
	echo "$(GREEN)Создана ветка: chore/$$name$(NC)"

help-branch:
	@echo ""
	@echo "$(BLUE)Правила именования веток:$(NC)"
	@echo ""
	@echo "$(YELLOW)feature/*$(NC)   - Новая функциональность"
	@echo "              Пример: feature/add-user-auth"
	@echo "              Команда: make branch-feature"
	@echo ""
	@echo "$(YELLOW)fix/*$(NC)       - Исправление багов"
	@echo "              Пример: fix/login-bug"
	@echo "              Команда: make branch-fix"
	@echo ""
	@echo "$(YELLOW)hotfix/*$(NC)    - Срочные исправления для production"
	@echo "              Пример: hotfix/critical-security-patch"
	@echo "              Команда: make branch-hotfix"
	@echo ""
	@echo "$(YELLOW)chore/*$(NC)     - Технические задачи (deps, configs, etc.)"
	@echo "              Пример: chore/update-dependencies"
	@echo "              Команда: make branch-chore"
	@echo ""
	@echo "$(BLUE)Workflow:$(NC)"
	@echo "  feature/fix/hotfix/chore/* -> dev -> test -> main"
	@echo ""
	@echo "$(BLUE)Примеры использования:$(NC)"
	@echo "  $$ make branch-feature"
	@echo "  > Feature name: add-oauth"
	@echo "  > Создана ветка: feature/add-oauth"
	@echo ""
	@echo "  $$ make branch-fix"
	@echo "  > Fix name: login-error"
	@echo "  > Создана ветка: fix/login-error"
	@echo ""

.DEFAULT_GOAL := help