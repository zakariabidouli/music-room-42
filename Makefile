.PHONY: install dev test load swagger

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
