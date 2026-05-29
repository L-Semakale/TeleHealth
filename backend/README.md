# Telemedicine Backend (Node + Prisma + Python ML)

This repository contains:
- `backend`: Node.js + Express + Prisma API
- `ml-service`: Python Flask triage microservice
- `docker-compose.yml`: local infra and service orchestration

## Implemented Modules
- Auth: register/login with JWT and bcrypt
- Profile update with password change flow
- Symptom submission + triage integration
- Consultation lifecycle and encrypted messaging (AES-256)
- Referrals and facilities directory with Redis cache
- Admin users/roles/status, consultations, analytics, facilities, health checks
- Standardized error response structure

## Quick Start
1. Copy env file:
   - `backend/backend/.env.example` -> `backend/backend/.env`
2. Start stack from `backend/`:
   - `docker compose up --build`
3. Run migrations and seed in API container:
   - `docker exec -it telemedicine-api npx prisma migrate dev --name init`
   - `docker exec -it telemedicine-api npm run prisma:seed`
4. API base URL:
   - `http://localhost:3000`

## Demo accounts (after seed)
| Role | Phone | Password |
|------|-------|----------|
| Admin | +26650000099 | password123 |
| Provider | +26650000088 | password123 |
| Patient | +26657712345 | password123 |

## Important Notes
- `AES_ENCRYPTION_KEY` must be exactly 32 chars.
- JWT payload includes `user_id`, `role`, `anonymous_id`.
- All protected routes require `Authorization: Bearer <token>`.
- ML service has fallback logic and always returns 200 with default routine classification on errors.

## Suggested Next Steps
- Add request validation layer (Zod/Joi)
- Add test suite (Jest + Supertest + pytest)
- Add round-robin provider assignment persistence
- Add Redis key prefix invalidation helper for facilities cache
