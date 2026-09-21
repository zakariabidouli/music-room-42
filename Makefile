.PHONY: install dev test load swagger up down logs build

install:
	cd backend && npm install
	@echo "mobile: flutter pub get (run inside mobile/)"

dev:
	cd backend && npm run dev

test:
	cd backend && npm test

swagger:
	cd backend && npm run swagger

load:
	k6 run docs/k6-vote.js

# ---- Docker: run the whole stack at once (db + backend + Flutter web) ----
up:
	docker compose up --build -d
	@echo "web UI:  http://localhost:8080"
	@echo "API:     http://localhost:3000/health"
	@echo "Swagger: http://localhost:3000/api/docs"

down:
	docker compose down

logs:
	docker compose logs -f

build:
	docker compose build
