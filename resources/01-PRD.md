# ScoreCaddie — Product Requirements Document (PRD)

## 1. Product Vision

ScoreCaddie is the definitive golf companion for Kenyan golfers. It provides **offline-first scoring**, **WHS 2024-compliant handicap tracking**, **AI-powered caddie coaching**, a **coaching marketplace**, and **social features** — all tailored to Kenyan golf courses and the local golf ecosystem.

**Tagline:** Your caddie. Your coach. Your game.

## 2. Target Market & Users

### Primary Market
- **Kenyan golfers** (scratch to 36+ handicap)
- **Coaches & caddies** seeking digital presence
- **Golf clubs & course managers** (indirect)

### User Personas

| Persona | Role | Needs | Pain Points |
|---------|------|-------|-------------|
| **David (Player)** | Amateur golfer, 18 HI | Track scores, calculate handicap, find caddies, improve game | No WHS system in Kenya, paper scorecards get lost, hard to find reliable caddies |
| **Grace (Coach)** | PGA-accredited coach | Manage students, create sessions, assign drills, track payments | Manual scheduling, no digital student management, payment tracking is messy |
| **Joseph (Caddie)** | Professional caddie | Get booked by players, manage availability, build reputation | No marketplace, irregular work, no rating system |

## 3. Feature Catalogue

### Core Features (Must-Have)

#### 3.1 Authentication & Profile
- **Email/password + Google OAuth** sign-up/sign-in
- **Role selection**: Player, Coach, or Caddie
- **Profile setup**: Name, handicap origin (new_golfer/self_reported/kgu_verified), home course, avatar with face verification, units (Yards/Meters)
- **Deep linking**: Friend invites via UID, group round join by code

#### 3.2 Round Scoring
- **Course selection**: Choose from 17 pre-seeded Kenyan courses (KGU official data)
- **Course intelligence**: View hole-by-hole stats, par, handicap index, distance before round
- **Live scoring**: Hole-by-hole with putts, fairway hits, GIR, penalties
- **ESC (Equitable Stroke Control)**: Net Double Bogey applied automatically
- **Score differential calculation**: WHS 2024 formula `(AGS - CR) * 113 / Slope`
- **9-hole support**: 9-hole to 18-hole transformation via Expected Score method
- **Add custom courses**: User-created courses with GPS coordinates

#### 3.3 Handicap System (WHS 2024)
- **Full WHS engine**: Score differential, Handicap Index (best 8 of 20), Course Handicap, Playing Handicap
- **Anchoring**: Soft cap (+3.0, 50% reduction) and hard cap (+5.0)
- **Exceptional Score Reduction (ESR)**: -1.0 for >7 diff, -2.0 for >10 diff
- **Low Index tracking**: Anchor index stored in profile
- **Provisional handicap**: For <3 rounds, 0 index with rounds-needed indicator

#### 3.4 AI Caddie (Daniel)
- **Voice shot logger**: Speak shots → Groq Whisper transcribes → Llama 3.1 extracts JSON
- **AI coaching feedback**: Llama 3.3 70B analyzes shot patterns → spoken via ElevenLabs TTS
- **Practice analysis**: Gemini 1.5 Flash analyzes practice session trends
- **Voice orb UI**: Animated visualizer for AI caddie interaction

#### 3.5 Practice Range
- **Free practice**: Log shots without drill structure
- **Drills**: 5 built-in drills (Clock Face, Lag Putting, Alignment Gate, Par 18 Chipping, Bunker Blast)
- **Custom drills**: Create drills with steps, targets, club types
- **Shot tracking**: Club, distance, shape, trajectory, quality
- **Session analytics**: Club performance, dispersion, trends

#### 3.6 Caddie/Coach Marketplace
- **Provider profiles**: Bio, phone/WhatsApp, certifications, experience, price, specializations
- **Booking system**: PENDING → CONFIRMED → IN_PROGRESS → COMPLETED → CANCELLED
- **Interaction tracking**: Call/WhatsApp contact logging
- **Reviews & ratings**: 5-star with comments
- **Provider discovery**: Browse by course, specialization, rating, location
- **Coaching sessions**: Group/Individual recurring sessions with enrollment
- **Payment tracking**: Cash, M-Pesa, Card; revenue breakdown by method

#### 3.7 Social Features
- **Friends system**: Add/accept, bi-directional
- **Group rounds**: Create with 6-char code, players join by code/QR, real-time live scoring
- **Leaderboards**: Global, friends-only, course-specific
- **Player profiles**: View others' stats, handicap, recent rounds
- **Chat**: Real-time messaging via Supabase Realtime

#### 3.8 Analytics & Achievements
- **Performance dashboard**: Avg score, best score, handicap trend, rounds count
- **Advanced stats**: Fairway %, GIR %, putts per round, score distribution
- **Streaks**: Weekly play streak tracking
- **50 achievements**: 5 categories (Scoring, Consistency, Activity, Explorer, Social)
- **Highlight cards**: Screenshot + share round highlights

### Nice-to-Have Features
- **AI pose detection**: Google MLKit swing analysis (planned)
- **Video upload**: Practice shot video recording + thumbnail
- **Calendar integration**: Add coaching sessions to device calendar
- **CSV export**: Export rounds data
- **QR sharing**: Share profile via QR code
- **Notifications**: Push notifications via Supabase

## 4. User Stories

### Player
1. "As a player, I want to start a round by selecting my course and tee box so I can track my score hole-by-hole."
2. "As a player, I want to see my WHS handicap update automatically after each round so I know my current index."
3. "As a player, I want to speak my practice shots and get AI coaching feedback so I can improve without typing."
4. "As a player, I want to find and book a local caddie so I can play unfamiliar courses."
5. "As a player, I want to join a group round with friends so we can compare live scores."
6. "As a player, I want to see my stats and achievements so I can track my progress."

### Coach
1. "As a coach, I want to create recurring coaching sessions with capacity limits so players can enroll."
2. "As a coach, I want to take attendance and track player progress so I can provide targeted guidance."
3. "As a coach, I want to assign drills to my students so they can practice between sessions."
4. "As a coach, I want to see payment breakdowns by method so I can manage my finances."

### Caddie
1. "As a caddie, I want a profile that showcases my experience, certifications, and ratings so players can find me."
2. "As a caddie, I want to manage my bookings and availability so I don't get double-booked."
3. "As a caddie, I want to be notified of new booking requests so I can respond quickly."

## 5. Success Metrics

| Metric | Target |
|--------|--------|
| Rounds recorded per user/week | ≥ 1 |
| Handicap index accuracy | ±0.5 of official WHS |
| AI caddie session completion rate | > 80% |
| Caddie booking conversion | > 30% |
| User retention (30-day) | > 60% |
| Crash-free rate | > 99.5% |
| Offline -> online sync success | > 99% |

## 6. Competitive Landscape

| Competitor | Strengths | Weaknesses vs ScoreCaddie |
|------------|-----------|--------------------------|
| **The Grint** | USGA WHS, social features | Not localized for Kenya, no AI caddie, no local marketplace |
| **Golfshot** | GPS tracking, course maps | No WHS index, no coaching features |
| **18Birdies** | Social, GPS, basic HI | No AI coaching, no offline-first, expensive premium |
| **V1 Game** | Video analysis | No scoring, no handicap tracking |

## 7. Constraints & Assumptions

### Technical Constraints
- Offline-first: All data must work without internet
- Local SQLite database is source of truth; Supabase cloud for backup & realtime
- AI services require internet (voice, coaching analysis)
- Flutter cross-platform: Android, iOS, Web, Windows, macOS, Linux

### Business Constraints
- Kenyan golf courses (17 seeded + user-added)
- KES currency for marketplace transactions
- WHS 2024 must be exact; no deviations from official formula
- API keys for Groq, ElevenLabs, Google Gemini embedded in client (no server-side proxy yet)

### Assumptions
- Users have smartphones (Android/iOS)
- Course data from KGU is accurate and up-to-date
- AI services maintain uptime and API availability
- Users will grant microphone, camera, and location permissions
