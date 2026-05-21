# Telemedicine Platform Frontend (Flutter)

Single Flutter project for mobile + web with role-based UX:
- Patient: mobile-first flow with bottom navigation
- Provider: web dashboard layout
- Admin: web dashboard layout

## API mode switch

Edit `lib/core/constants/app_config.dart`:
- `ApiMode.mock` for local mock data
- `ApiMode.real` to call backend at `baseUrl`

## Mock role login shortcuts

In mock mode, login role is inferred by phone:
- ends with `88` -> provider
- ends with `99` -> admin
- otherwise -> patient

### Testing credentials (mock mode)

Use any password with at least 6 characters:
- Patient: `+266500001`
- Provider: `+266500088`
- Admin: `+266500099`

## Setup

1. Install Flutter SDK
2. Run:
   - `flutter pub get`
   - `flutter run` (mobile)
   - `flutter run -d chrome` (web)
