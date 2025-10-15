.PHONY: help generate clean install-tools pr-view release-view repo-view check-gh check-protoc check-deps
.PHONY: test lint fmt vet build ci-local pre-commit

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

help:
	@echo "Доступные команды:"
	@echo ""
	@echo "Проверка окружения:"
	@echo "  make check-deps     - Проверить все зависимости"
	@echo ""
	@echo "GitHub команды:"
	@echo "  make pr-view        - Открыть Pull Requests в браузере"
	@echo "  make release-view   - Открыть Releases в браузере"
	@echo "  make repo-view      - Открыть репозиторий в браузере"
	@echo "  make actions-view   - Открыть GitHub Actions в браузере"
	@echo ""
	@echo "Система: $(OS)"
	@echo ""
	@echo "Примечание: для GitHub команд желательно установить GitHub CLI:"
	@echo "  brew install gh     (macOS)"
	@echo "  Или используйте: make <команда> без gh"

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

# Проверка всех зависимостей
check-deps:
	@echo ""
	@echo "Проверка Go..."
	@if which go > /dev/null 2>&1; then \
		echo "SUCCESS. Go установлен: $(go version)"; \
	else \
		echo "FAIL. Go НЕ установлен!"; \
		echo "Скачайте с https://go.dev/dl/"; \
		exit 1; \
	fi
	@echo ""
	@echo "Проверка make..."
	@if which make > /dev/null 2>&1; then \
		echo "SUCCESS. make установлен: $(make --version | head -n 1)"; \
	else \
		echo "FAIL. Make НЕ установлен (но вы же его используете...)"; \
	fi
	@echo ""
	@echo "Опционально: GitHub CLI"
	@if which gh > /dev/null 2>&1; then \
		echo "SUCCESS. gh установлен: $(gh --version | head -n 1)"; \
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
	@echo "$(GREEN) Форматирование завершено$(NC)"

lint:
	@echo "$(BLUE)Запуск линтера...$(NC)"
	@if which golangci-lint > /dev/null 2>&1; then \
		golangci-lint run ./...; \
		echo "$(GREEN) Линтер завершен$(NC)"; \
	else \
		echo "$(RED) golangci-lint не установлен!$(NC)"; \
		echo "$(YELLOW)Запустите: make install-tools$(NC)"; \
		exit 1; \
	fi

vet:
	@echo "$(BLUE)Статический анализ (go vet)...$(NC)"
	@go vet ./...
	@echo "$(GREEN) Анализ завершен$(NC)"

build:
	@echo "$(BLUE)Сборка проекта...$(NC)"
	@go build -v ./...
	@echo "$(GREEN) Сборка завершена$(NC)"

pre-commit: fmt vet lint test
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN) Все проверки пройдены! Можно делать commit.$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"



# Проверка наличия gh CLI
check-gh:
	@which gh > /dev/null 2>&1 || (echo "FAIL. GitHub CLI не установлен. Открываю через браузер..." && exit 1)

# GitHub команды с fallback на браузер
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

.DEFAULT_GOAL := help