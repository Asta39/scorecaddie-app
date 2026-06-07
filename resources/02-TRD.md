# ScoreCaddie — Technical Requirements Document (TRD)

## 1. Technology Stack

### Frontend
| Layer | Technology | Version/Config |
|-------|------------|----------------|
| Language | Dart | SDK ^3.11.3 |
| Framework | Flutter | MaterialApp.router |
| State Management | Riverpod | flutter_riverpod ^2.6.1 + riverpod_annotation ^2.6.1 |
| Routing | GoRouter | ^14.8.1, 45+ routes with redirect guards |
| Local DB | Drift (SQLite) | ^2.24.0, schema v51, 21 tables |
| Charts | fl_chart | ^0.70.2 |
| UI | Google Fonts (Inter), Lucide Icons, Lottie, Flutter Animate | — |
| Code Generation | build_runner + drift_dev + riverpod_generator | dev dependencies |

### Backend / Cloud
| Service | Purpose | Integration |
|---------|---------|-------------|
| **Supabase** | Auth, PostgreSQL, Realtime, Storage | supabase_flutter ^2.8.1 |
| **Supabase Auth** | Email/password + Google OAuth (PKCE) | PKCE auth flow |
| **Supabase PostgreSQL** | Cloud database (30 migrations) | REST + Realtime subscriptions |
| **Supabase Realtime** | Live group scores, messages, bookings | WebSocket streams |
| **Supabase Storage** | Profile photos, certifications, videos | `user_assets` bucket |

### AI Services
| Service | Model | Purpose | API Key Location |
|---------|-------|---------|-----------------|
| **Groq** | Whisper large-v3-turbo | Speech-to-text for voice shot logging | Hardcoded in groq_service.dart |
| **Groq** | Llama 3.1 8B Instant | Shot data extraction (transcript → JSON) | Same key |
| **Groq** | Llama 3.3 70B Versatile | AI Caddie "Daniel" coaching feedback | Same key |
| **ElevenLabs** | eleven_flash_v2_5 | Text-to-speech (Voice: Daniel, British) | Hardcoded in ai_caddie_service.dart |
| **Google Gemini** | Gemini 1.5 Flash | Practice session analysis, performance trends | Hardcoded in practice_analysis_service.dart |

### Third-Party Packages (63 total)
Key categories:
- **Scoring**: mobile_scanner, qr_flutter, csv
- **Media**: image_picker, camera, video_player, video_thumbnail
- **AI/ML**: google_mlkit_pose_detection, google_mlkit_face_detection, google_generative_ai
- **Location**: geolocator
- **Connectivity**: connectivity_plus
- **Sharing**: share_plus, screenshot, url_launcher
- **Audio**: record, just_audio
- **Permissions**: permission_handler
- **Calendar**: add_2_calendar
- **Storage**: shared_preferences, http, dio

## 2. Architecture

### Offline-First Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Flutter App Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  Screens (45+ GoRouter routes)                                  │
│  Providers (Riverpod: Stream/Future/StateNotifier)              │
│  Services (Business Logic Layer)                                │
│  Models (Data Classes)                                          │
├─────────────────────────────────────────────────────────────────┤
│  Local Database (Drift SQLite - Source of Truth)                │
│  21 tables, schema v51                                          │
├─────────────────────────────────────────────────────────────────┤
│  Sync Engine (SyncService)                                      │
│  Push: Local → Supabase (idempotent upserts)                   │
│  Pull: Supabase → Local (paginated, deduplicated)              │
├─────────────────────────────────────────────────────────────────┤
│  Network Layer                                                  │
│  Supabase REST + Realtime WebSocket                             │
│  Groq REST API (AI services)                                    │
│  ElevenLabs REST API (TTS)                                      │
│  Google Gemini REST API (analysis)                              │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Pattern
```
User Action → Widget → Provider (reactive) → Service → Drift DB (local write)
                                                          ↓
                                                    SyncService
                                                          ↓
                                                 Supabase (cloud)
                                                          ↓
                                            Realtime subscription → Provider → Widget update
```

### Key Design Decisions

1. **Drift (SQLite) as source of truth** — All writes go to local DB first. Sync happens asynchronously.
2. **Riverpod StreamProviders** — Watch local DB via Drift `.watch()` methods for reactive UI.
3. **Supabase as cloud replica** — Used for cross-device sync, realtime group scoring, and chat.
4. **Deterministic UUIDs** — v5 UUIDs with stable namespace prevent duplicate creation on re-sync.
5. **Role-based routing** — GoRouter redirect guard checks auth + profile completeness before every route.

## 3. Service Layer

### Core Services (`lib/core/services/`)
| Service | Responsibility | Key Methods |
|---------|---------------|-------------|
| `SupabaseAuthService` | Auth lifecycle | signInWithEmail, registerWithEmail, signInWithGoogle, signOut, authStateChanges |
| `ProfileService` | Profile CRUD + username validation | ensureProfile, updateProfile, checkUsername |
| `CaddieService` | Booking CRUD + realtime | createBooking, updateBooking, watchBookings |
| `CoachingService` | Session management | createSession, enroll, takeAttendance, recordPayment, manageDrills |
| `FriendService` | Social connections | addFriend, acceptRequest, syncMyProfileToCloud |
| `LeaderboardService` | Rankings | globalLeaderboard, friendsLeaderboard, courseLeaderboard |
| `InteractionService` | Contact logging | logCall, logWhatsApp, getPendingInteractions |
| `NotificationService` | Push notifications | init, showNotification |
| `HighlightCardService` | Screenshot/share | captureCard, shareCard |
| `AICaddieService` | AI coaching + TTS | getCoachingFeedback, textToSpeech |
| `PracticeAnalysisService` | Gemini analysis | analyzeSession, analyzePerformance |
| `AchievementService` | Achievement checking | checkAndUnlock (against rounds/holes/streaks) |

### Cloud Services (`lib/core/cloud/`)
| Service | Responsibility |
|---------|---------------|
| `ApiService` | Supabase REST (syncProfile, getProfile) |
| `GroqService` | Voice transcription (Whisper) + shot extraction (Llama) |
| `GroupSyncService` | Group round realtime sync (create, join, score, certify) |
| `SupabaseService` | Realtime streams (Bookings, Messages, status) |
| `SupabaseSocialService` | Friends & leaderboard ops |
| `SupabaseStorageService` | File uploads (profile photos, certifications) |
| `SyncService` | Master sync engine (953 lines) |

## 4. State Management (Riverpod Providers)

### Provider Architecture (`lib/providers/`)

**Stream Providers (reactive DB watchers):**
- `authStateProvider` — Supabase auth state changes
- `userProfileProvider` — Local DB profile stream
- `handicapProvider` — Computed WHS index from round differentials
- `roundsProvider` / `recentRoundsProvider` — Round list streams
- `friendsProvider` / `friendRequestsProvider` — Social graph
- `userBookingsProvider` / `providerBookingsProvider` — Booking streams
- `allProvidersProvider` / `specificProviderProvider` — Marketplace
- `coachSessionsProvider` — Coaching session list

**Future Providers (async computation):**
- `advancedStatsProvider` — Complex stat aggregation
- `practiceAnalyticsProvider` — Practice data analysis
- `nearbyCoursesProvider` — Geolocation-based sorting

**Controller / State Providers:**
- `syncControllerProvider` — Auto-sync timer (10s interval)
- `handicapTrackerProvider` — Monitors HI changes, persists to DB
- `navIndexProvider` — Bottom nav tab index
- `themeModeProvider` — Light/dark preference

## 5. WHS 2024 Engine

### File: `lib/core/utils/whs_engine.dart` (192 lines)

**Formulas implemented:**

| Step | Formula | Notes |
|------|---------|-------|
| **ESC Cap** | `par + 2 + floor(CH/18) + (1 if strokeIndex <= CH%18)` | Net Double Bogey |
| **Score Differential** | `(AGS - CR - PCC) * 113 / Slope` | 18-hole standard |
| **9-hole Differential** | `(9h_AGS - 9h_CR - 0.5*PCC) * 113 / 9h_Slope + (HI * 0.52 + 1.15)` | Expected Score method |
| **Handicap Index** | Best N of last 20 * 0.96 + adjustments | N varies by count (1-8) |
| **Soft Cap** | `anchor + 3.0 + (excess - 3.0) * 0.5` | 50% reduction above 3.0 |
| **Hard Cap** | `anchor + 5.0` | Absolute limit |
| **ESR** | `-2.0` if diff > 10 below index, `-1.0` if > 7 | Exceptional score reduction |
| **Course Handicap** | `HI * (Slope/113) + (CR - Par)` | 2024 formula |
| **Playing Handicap** | `CH * allowance` | 0.95 for stroke play |

## 6. Navigation & Routing

### GoRouter Configuration (712 lines in `app_router.dart`)

**Guard Logic:**
1. Splash → let animation complete (no redirect)
2. Not logged in → `/auth`
3. Logged in, profile loading → stay (wait for data)
4. Logged in, on `/auth`, profile complete → `/`
5. Logged in, profile incomplete, at root → `/select-role`
6. Deep resilience: don't redirect from deep pages on transient profile null

**Route Groups:**
| Group | Paths | Count |
|-------|-------|-------|
| Auth/Onboarding | /splash, /auth, /loading, /select-role, /player-onboarding, /provider-onboarding | 6 |
| Shell (Bottom Nav) | /, /practice, /analytics, /caddie, /leaderboard, /achievements, /profile, coach sub-routes | 18 |
| Scorecard | /select-course, /scoring, /group-scoring, /group/certification/:id, /courses/add | 5 |
| Practice | /practice/session/:id, /practice/summary/:id, /practice/analytics, /practice/drills/new | 4 |
| Marketplace | /marketplace/provider/:id, /marketplace/coach/:coachId/sessions, /session/booking | 3 |
| Social | /profile/friends, /friend/add/:uid, /player/:id, /chat/:id, /round/lobby/:id, /round/join/:code | 6 |
| History | /round/:roundId, /rounds-history | 2 |
| Profile | /profile/bag, /profile/settings, /help | 3 |

## 7. Testing Strategy

### Current Tests (3 files)
| Test File | Tests | Coverage |
|-----------|-------|----------|
| `whs_engine_test.dart` | 10 unit tests | Score diff, HI, Course HI, ESC cap |
| `database_test.dart` | Course seeding, duplicate prevention | Database layer |
| `widget_test.dart` | Basic smoke (outdated) | Widget layer |

### Required Test Coverage
- **Unit tests**: WHS engine (all formulas), service methods, model parsing
- **Widget tests**: Auth flow, onboarding, scoring screen, practice screen
- **Integration tests**: Full round flow, group round flow, sync cycle
- **Golden tests**: Key screens (dashboard, profile, course intel)

## 8. Performance Targets

| Metric | Target |
|--------|--------|
| App cold start | < 3s |
| Screen navigation | < 300ms |
| Database query (local) | < 50ms |
| Sync round to cloud | < 5s |
| Voice transcription | < 3s |
| AI coaching response | < 12s |
| TTS generation | < 5s |
| Memory usage (idle) | < 100MB |

## 9. Security Considerations

- API keys hardcoded in client (known limitation — no server-side proxy)
- Supabase Row Level Security (RLS) policies manage data access
- PKCE auth flow prevents token interception
- Profile photo verification via face detection
- Local DB encrypted at rest via device storage
- No secrets in git; keys in source code (mitigated by client-only nature)

## 10. Error Handling

- `ConnectionGuard` wraps network calls, shows `OfflineBottomSheet` on `SocketException`
- Drift transactions with rollback on failure
- Sync engine marks records with `isSynced` flag; retries on next cycle
- AI services have fallback messages for timeout/error conditions
- `try/catch` patterns with `debugPrint` logging throughout
