.PHONY: install dev test load swagger up down logs build

install:
	cd backend && npm install
	@echo "mobile: flutter pub get (run inside mobile/)"

dev:
	cd backend && npm run dev

test:
	cd backend && npm test
	if command -v flutter >/dev/null 2>&1; then cd mobile && flutter test; else echo "mobile: flutter SDK not installed — skipping (CI runs flutter test)"; fi

swagger:
	cd backend && npm run swagger

load:
	k6 run -e BASE_URL=http://localhost:3001 docs/k6-vote.js
	k6 run -e BASE_URL=http://localhost:3001 docs/k6-playlist.js

# ---- Docker: run the whole stack at once (db + backend + Flutter web) ----
up:
	docker compose up --build -d
	@echo "web UI:  http://localhost:8081"
	@echo "API:     http://localhost:3001/health"
	@echo "Swagger: http://localhost:3001/api/docs"

down:
	docker compose down

logs:
	docker compose logs -f

build:
	docker compose build

re: 
	docker compose down
	docker compose build --no-cache
	docker compose up -d
