# ScoreCaddie — Implementation Plan

## Overview

**Current Status**: Phase 1 complete (foundation), Phase 2 in progress, Phases 3-4 partially implemented.
**Version**: 1.0.0+1
**Platforms**: Android, iOS, Web, Windows, macOS, Linux

---

## Phase 1: Foundation ✅ (COMPLETE)

### 1.1 Project Scaffolding
| Task | Files | Status |
|------|-------|--------|
| Flutter project setup | pubspec.yaml, analysis_options.yaml | ✅ |
| MaterialApp with router | main.dart, app.dart | ✅ |
| Theme system (light/dark) | app_theme.dart, glass_card.dart | ✅ |
| Riverpod provider setup | providers/ | ✅ |
| GoRouter with redirect guards | app_router.dart | ✅ |

### 1.2 Authentication
| Task | Files | Status |
|------|-------|--------|
| Supabase initialization | main.dart, app_config.dart | ✅ |
| Email/password auth | supabase_auth_service.dart | ✅ |
| Google OAuth (PKCE) | supabase_auth_service.dart | ✅ |
| Auth state provider | auth_providers.dart | ✅ |
| Auth screens | splash_screen.dart, auth_screen.dart | ✅ |

### 1.3 Onboarding
| Task | Files | Status |
|------|-------|--------|
| Role selection | role_selection_screen.dart | ✅ |
| Player onboarding | player_onboarding_screen.dart | ✅ |
| Provider onboarding | provider_onboarding_screen.dart | ✅ |
| Profile creation flow | profile_service.dart | ✅ |
| Profile guard in router | app_router.dart (RouterNotifier) | ✅ |

### 1.4 Database Foundation
| Task | Files | Status |
|------|-------|--------|
| Drift setup (21 tables) | database.dart (schema v51) | ✅ |
| Course seeding (17 courses) | seed_courses.dart | ✅ |
| Drill seeding (5 built-in) | database.dart (syncPrimaryDrills) | ✅ |
| Database providers | database_providers.dart | ✅ |

### 1.5 Core Routing & Shell
| Task | Files | Status |
|------|-------|--------|
| AppShell with bottom nav | app_shell.dart (3 role variants) | ✅ |
| Dashboard (player/coach/caddie) | dashboard_screen.dart | ✅ |
| Navigation state | ui_providers.dart | ✅ |

### 1.6 Basic Scoring
| Task | Files | Status |
|------|-------|--------|
| Course selection | course_select_screen.dart | ✅ |
| Course intelligence | course_intel_screen.dart | ✅ |
| Hole-by-hole scoring | scoring_screen.dart | ✅ |
| Round save + sync | sync_service.dart (syncRound) | ✅ |
| Round detail view | round_detail_screen.dart | ✅ |
| Rounds history | rounds_history_screen.dart | ✅ |

### 1.7 WHS Handicap Engine
| Task | Files | Status |
|------|-------|--------|
| ESC cap calculation | whs_engine.dart (calculateESCCap) | ✅ |
| Score differential | whs_engine.dart (calculateScoreDifferential) | ✅ |
| 9-hole transformation | whs_engine.dart (calculate9HoleTotalDifferential) | ✅ |
| Handicap Index (best N of 20) | whs_engine.dart (calculateHandicapIndex) | ✅ |
| Soft/hard caps + anchoring | whs_engine.dart (applyYearlyCap) | ✅ |
| ESR (exceptional score) | whs_engine.dart (calculateExceptionalScoreReduction) | ✅ |
| Course/playing handicap | whs_engine.dart | ✅ |
| Reactive handicap provider | handicap_provider.dart | ✅ |
| Auto-persist tracker | handicap_provider.dart (handicapTrackerProvider) | ✅ |
| Unit tests (10) | whs_engine_test.dart | ✅ |

---

## Phase 2: AI & Practice 🔶 (IN PROGRESS)

### 2.1 AI Voice Shot Logger
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Groq Whisper integration | groq_service.dart (transcribe) | ✅ | High |
| Llama shot extraction | groq_service.dart (extractShot) | ✅ | High |
| Audio recording UI | voice_logger_screen.dart | 🔶 Partial | High |
| Voice orb visualizer | voice_orb_visualizer.dart | 🔶 Partial | Medium |
| Shot confirmation UI | practice_session_screen.dart | 🔶 Partial | High |

### 2.2 AI Caddie (Daniel)
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Llama 3.3 coaching feedback | ai_caddie_service.dart (getCoachingFeedback) | ✅ | High |
| ElevenLabs TTS | ai_caddie_service.dart (textToSpeech) | ✅ | High |
| Voice toggle setting | ai_caddie_service.dart | ✅ | Low |
| Caddie orb UI | caddie_orb_screen.dart | 🔶 Partial | Medium |

### 2.3 Practice Range
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Practice hub screen | practice_range_screen.dart | ✅ | High |
| Session screen | practice_session_screen.dart | ✅ | High |
| Shot logging (manual) | practice_session_screen.dart | ✅ | High |
| Session summary | session_summary_screen.dart | ✅ | High |
| Practice analytics | practice_analytics_screen.dart | 🔶 Partial | Medium |
| Built-in drills | database.dart (syncPrimaryDrills, 5 drills) | ✅ | High |
| Custom drill builder | custom_drill_builder_screen.dart | ✅ | Medium |

### 2.4 Gemini Analysis
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Session analysis | practice_analysis_service.dart (analyzeSession) | ✅ | Medium |
| Performance trends | practice_analysis_service.dart (analyzePerformance) | ✅ | Medium |
| Provider setup | practice_analysis_service.dart (provider) | ✅ | Low |

### 2.5 Video & Pose Detection (Planned)
| Task | Priority |
|------|----------|
| Google MLKit pose detection integration | Low |
| Video recording during practice | Low |
| Swing analysis overlay | Low |

---

## Phase 3: Marketplace & Coaching 🔶 (PARTIALLY COMPLETE)

### 3.1 Provider Profiles
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Provider table + CRUD | database.dart (Providers table) | ✅ | High |
| Provider onboarding | provider_onboarding_screen.dart | ✅ | High |
| Provider preview screen | provider_preview_screen.dart | ✅ | High |
| Caddie marketplace | caddie_marketplace_screen.dart | ✅ | High |
| Provider-specific queries | caddie_providers.dart | ✅ | Medium |

### 3.2 Caddie Bookings
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Booking model + table | booking_model.dart, Bookings table | ✅ | High |
| Booking CRUD service | caddie_service.dart, supabase_service.dart | ✅ | High |
| Booking status flow | caddie_service.dart | ✅ | High |
| Caddie home (active bookings) | caddie_home_screen.dart | ✅ | High |
| Caddie dashboard | caddie_dashboard_screen.dart | ✅ | Medium |
| Caddie payments | caddie_payments_screen.dart | ✅ | Medium |
| Caddie rounds | caddie_rounds_screen.dart | ✅ | Medium |

### 3.3 Interaction Tracking
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Interaction model + table | Interactions table | ✅ | High |
| Interaction service | interaction_service.dart | ✅ | High |
| Booking confirmation prompt | app_shell.dart (_checkPendingInteractions) | ✅ | High |
| Inquiry creation | supabase_service.dart | ✅ | Medium |

### 3.4 Reviews & Ratings
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Reviews table + CRUD | Reviews table, sync_service.dart | ✅ | High |
| Rating prompt (post-booking) | app_shell.dart (_showRatingPrompt) | ✅ | High |
| Review display on profiles | provider_preview_screen.dart | ✅ | Medium |
| Average rating calculation | database.dart (updateProviderRating) | ✅ | Medium |

### 3.5 Coaching Sessions
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Coaching model (session, occurrence, enrollment, attendance) | coaching_model.dart, coaching_summary.dart | ✅ | High |
| Coaching service (CRUD + RPC) | coaching_service.dart (709 lines) | ✅ | High |
| Supabase RPC functions (8) | supabase/migrations/ | ✅ | High |
| Create session screen | create_session_screen.dart | ✅ | High |
| Edit session screen | edit_session_screen.dart | ✅ | Medium |
| Coach sessions list | coach_sessions_screen.dart | ✅ | High |
| Session details | session_details_screen.dart | ✅ | High |
| Coach students | coach_students_screen.dart | ✅ | High |
| Coach payments management | coach_payment_management_screen.dart | ✅ | Medium |
| Coach drills management | coach_drills_screen.dart, coach_drill_builder_screen.dart | ✅ | Medium |
| Public sessions view | coach_public_sessions_screen.dart | ✅ | High |
| Session booking/enrollment | session_booking_screen.dart | ✅ | High |
| Player session details | player_session_details_screen.dart | ✅ | Medium |
| Coaching providers | coaching_providers.dart | ✅ | Low |
| Calendar integration | calendar_helper.dart | ✅ | Low |

---

## Phase 4: Social & Gamification 🔶 (PARTIALLY COMPLETE)

### 4.1 Social Features
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Friends table + CRUD | Friends table | ✅ | High |
| Friend service | friend_service.dart | ✅ | High |
| Friends screen | friends_screen.dart | ✅ | High |
| Friend add/deep link | app_router.dart (FriendAddHandleScreen) | ✅ | High |
| Player profile screen | player_profile_screen.dart | ✅ | Medium |
| Friend providers | social_providers.dart | ✅ | Medium |
| Real-time chat | chat_screen.dart, Messages table, supabase_service.dart | ✅ | Medium |

### 4.2 Group Rounds
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| GroupRound tables + queries | GroupRounds, GroupRoundParticipants, HoleScores.participantId | ✅ | High |
| Group sync service | group_sync_service.dart | ✅ | High |
| Group scoring screen | group_scoring_screen.dart | ✅ | High |
| Group certification screen | group_certification_screen.dart | ✅ | High |
| Join round (code + deep link) | app_router.dart (JoinRoundHandleScreen) | ✅ | High |
| Group lobby | group_round_lobby.dart | ✅ | High |
| QR code generation | qr_flutter dependency | ✅ | Low |
| QR code scanning | mobile_scanner dependency | ✅ | Low |

### 4.3 Leaderboards
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Leaderboard service | leaderboard_service.dart | ✅ | Medium |
| Leaderboard screen | leaderboard_screen.dart | ✅ | Medium |
| Global/friends/course tabs | leaderboard_screen.dart | ✅ | Medium |
| Social providers | social_providers.dart (leaderboardStreamProvider) | ✅ | Low |

### 4.4 Achievements
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| Achievement model (50 achievements) | achievement_model.dart | ✅ | Medium |
| Achievement service | achievement_service.dart | ✅ | Medium |
| Achievement gallery screen | achievements_gallery_screen.dart | ✅ | Medium |
| Achievement unlock dialog | achievement_dialog.dart | ✅ | Medium |

### 4.5 Sync & Offline
| Task | Files | Status | Priority |
|------|-------|--------|----------|
| SyncService (master engine) | sync_service.dart (953 lines) | ✅ | High |
| KGU data pull (paginated) | sync_service.dart (pullKguData) | ✅ | High |
| Cross-device round restore | sync_service.dart (pullRounds) | ✅ | High |
| Auto-sync controller | sync_provider.dart (SyncController, 10s timer) | ✅ | High |
| Network-aware sync | app_shell.dart (Connectivity listener) | ✅ | Medium |
| Connection guard | connection_guard.dart | ✅ | Medium |
| Supabase profile sync | api_service.dart | ✅ | High |

---

## Remaining Work & Known Issues

### High Priority
1. **Voice Logger UI** — Microphone recording UI needs refinement (record package integration)
2. **AI Caddie Orb** — Voice orb visualizer animation needs polish
3. **Test Coverage** — Only 3 test files exist; need comprehensive unit + widget + integration tests
4. **API Key Security** — All API keys hardcoded in source; should use server-side proxy or env vars

### Medium Priority
5. **Course Intel Enhancement** — Add more visual hole maps, distance tracking
6. **Practice Analytics** — Charts and deeper insights (fl_chart integration exists but limited usage)
7. **Offline Caching for Courses** — Pre-download KGU course data for full offline use
8. **Notification System** — Push notifications via Supabase (notification_service.dart scaffold exists)

### Low Priority
9. **Pose Detection** — Google MLKit swing analysis integration
10. **Video Analysis** — Swing recording + playback + overlay
11. **Course GPS Maps** — Interactive course maps with GPS positioning
12. **Tournament Mode** — Multi-round tournament scoring
13. **CSV Export** — Export rounds data to CSV
14. **Dark Mode Polish** — Dark theme exists but some screens may need adjustment

---

## Dependency Graph

```
Phase 1 (Foundation)
├── Auth ───────────────────────────────────────────────────
│   └── Onboarding ─────────────────────────────────────────
│       └── Database (Drift + Supabase) ────────────────────
│           └── Course Data (17 seeded courses) ────────────
│               └── Scoring (hole-by-hole + WHS engine) ────
│                   └── Sync Engine (push/pull to Supabase) ─
│                       └── Handicap Tracker (auto-update) ──
│
Phase 2 (AI & Practice)
├── Practice Session ──────── AI Voice Logger ──────── AI Caddie
│       │                          │                         │
│       └────── Gemini Analysis ───┘                         │
│                                                            │
Phase 3 (Marketplace)
├── Provider Profiles ──── Caddie Booking ──── Reviews/Ratings
│       │                                                    │
│       └── Coaching Sessions ───── Enrollment ───── Payments
│
Phase 4 (Social)
├── Friends ──── Group Rounds ──── Leaderboards ──── Chat
│       └── Achievements (checks all other systems)
```

---

## Testing Plan

### Current Coverage (3 files, need expansion)

| Area | Current | Target | Priority |
|------|---------|--------|----------|
| WHS Engine (unit) | 10 tests ✅ | 25+ tests | High |
| Database (unit) | 1 test (seeding) | 15+ tests | Medium |
| Service layer (unit) | 0 | 20+ tests | Medium |
| Widget tests | 1 (outdated) | 15+ tests | Medium |
| Integration tests | 0 | 5+ tests | High |
| Golden tests | 0 | 10+ tests | Low |

### Critical Test Cases Needed
1. **WHS Engine**: All edge cases (0 rounds, 1 round, 20+ rounds, 9-hole, caps, ESR, PCC)
2. **Sync Engine**: Conflict resolution, idempotent upserts, offline queue
3. **Scoring Flow**: Full 18-hole round, 9-hole, ESC application, differential calculation
4. **Group Round**: Create → join → score → certify flow
5. **Booking**: Create → confirm → complete → rate flow
6. **Coaching**: Create session → enroll → attend → complete flow
