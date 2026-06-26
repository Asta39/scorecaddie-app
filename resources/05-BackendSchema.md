# ScoreCaddie — Backend Schema Document

## 1. Local Database (Drift SQLite)

### Overview
- **Engine**: Drift (SQLite ORM)
- **Schema version**: 51
- **Tables**: 21
- **File location**: `score_caddie.sqlite` in app documents directory
- **Connection**: `NativeDatabase.createInBackground(file)` (background thread)

---

### 1.1 Core Domain Tables

#### UserProfiles
Primary user account table. Each row = one user.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local primary key |
| uid | TEXT UNIQUE | Yes | — | Supabase Auth UID |
| email | TEXT | Yes | — | User email |
| name | TEXT | Yes | 'Golfer' | Display name |
| avatarUrl | TEXT | Yes | — | Profile photo URL (http or file://) |
| handicap | REAL | Yes | — | Current WHS Handicap Index |
| handicapOrigin | TEXT | Yes | 'new_golfer' | new_golfer, self_reported, kgu_verified |
| importedIndex | REAL | Yes | — | Initial imported index |
| isProvisional | BOOL | Yes | true | Whether HI is provisional (<3 rounds) |
| provisionalRounds | INT | Yes | 0 | Rounds used for provisional calc |
| anchorIndex | REAL | Yes | — | Lowest index (for WHS caps) |
| homeCourseId | INT | Yes | — | FK to Courses |
| homeCourseName | TEXT | Yes | — | Denormalized course name |
| skillLevel | TEXT | Yes | — | Beginner, Intermediate, Advanced |
| preferredTees | TEXT | Yes | — | e.g., "White", "Simba" |
| playStyle | TEXT | Yes | — | Aggressive, Conservative, Balanced |
| units | TEXT | Yes | 'Yards' | Yards or Meters |
| themeMode | TEXT | Yes | 'System' | Light, Dark, System |
| privacyLevel | TEXT | Yes | 'Private' | Private, Friends, Public |
| badgesJson | TEXT | Yes | '[]' | JSON array of achievement IDs |
| role | TEXT | Yes | — | player, coach, caddie |
| profileComplete | BOOL | Yes | false | Onboarding completed |
| pfpVerified | BOOL | Yes | false | Face verification passed |
| providerStatus | TEXT | Yes | 'OFFLINE' | AVAILABLE, ON_ROUND, OFFLINE |
| currentBookingId | TEXT | Yes | — | Active booking server ID |
| passportPhotoUrl | TEXT | Yes | — | Verified passport photo |
| createdAt | DATETIME | Yes | now() | Row creation |
| updatedAt | DATETIME | Yes | now() | Last update |

#### Clubs
Golf clubs in a user's bag.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| userId | TEXT | No | — | FK to UserProfiles.uid |
| type | TEXT | No | — | driver, 3 wood, 7 iron, putter, etc. |
| brand | TEXT | Yes | — | e.g., TaylorMade, Callaway |
| model | TEXT | Yes | — | e.g., Stealth 2, Apex |
| loft | REAL | Yes | — | Loft in degrees |
| averageDistance | REAL | Yes | — | User's avg distance |
| notes | TEXT | Yes | — | User notes |
| photoUrl | TEXT | Yes | — | Club photo |
| supabaseId | TEXT | Yes | — | Cloud UUID |
| createdAt | DATETIME | Yes | now() | |

#### Courses
Golf courses (17 Kenyan seeded + user-added).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| supabaseId | TEXT | Yes | — | Cloud UUID (KGU official) |
| userId | TEXT | Yes | — | Creator (null = official KGU) |
| name | TEXT | No | — | Course name |
| location | TEXT | Yes | '' | Area/location |
| city | TEXT | Yes | — | City |
| region | TEXT | Yes | — | County/region |
| totalHoles | INT | Yes | 18 | 9 or 18 |
| par | INT | Yes | — | Total par (deprecated in favor of par18) |
| par18 | INT | Yes | — | 18-hole par |
| par9front | INT | Yes | — | Front 9 par |
| par9back | INT | Yes | — | Back 9 par |
| holePars | TEXT | Yes | '[]' | JSON array of par per hole |
| teeData | TEXT | Yes | '[]' | JSON array of tee box data |
| isUserEdited | BOOL | Yes | false | User modified course |
| syncId | TEXT | Yes | — | Legacy sync field |
| caddieFee | REAL | Yes | 1000.0 | Default caddie fee (KES) |
| latitude | REAL | Yes | — | For location sorting |
| longitude | REAL | Yes | — | For location sorting |
| createdAt | DATETIME | Yes | now() | |
| updatedAt | DATETIME | Yes | now() | |
| **Unique**: supabaseId, (name + location) |

#### Tees
Tee boxes per course.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| courseId | INT | No | — | FK to Courses |
| name | TEXT | No | — | "White", "Simba", "Yellow", etc. |
| gender | TEXT | Yes | 'male' | male, female |
| courseRating | REAL | No | — | USGA course rating |
| slopeRating | INT | No | — | USGA slope rating |
| par | INT | Yes | — | Par from this tee |
| yardage | INT | Yes | — | Total yardage |
| courseRatingFront | REAL | Yes | — | 9-hole front CR |
| slopeRatingFront | INT | Yes | — | 9-hole front SR |
| courseRatingBack | REAL | Yes | — | 9-hole back CR |
| slopeRatingBack | INT | Yes | — | 9-hole back SR |
| **Unique**: (courseId, name, gender) |

#### CourseHoles
Hole-by-hole data for each course/tee combination.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| courseId | INT | No | — | FK to Courses |
| teeId | INT | Yes | — | FK to Tees (null = generic) |
| holeNumber | INT | No | — | 1-18 |
| par | INT | No | — | Par for this hole |
| handicapIndex | INT | Yes | — | Stroke index |
| distance | INT | Yes | — | Yards |
| **Unique**: (courseId, teeId, holeNumber) |

#### Rounds
Completed rounds with WHS data.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| supabaseId | TEXT | Yes | — | Cloud UUID |
| userId | TEXT | Yes | — | FK to UserProfiles.uid |
| courseId | INT | No | — | FK to Courses |
| teeId | INT | Yes | — | FK to Tees |
| courseName | TEXT | Yes | '' | Denormalized |
| holesPlayed | INT | Yes | 18 | 9 or 18 |
| tee | TEXT | Yes | '' | Tee name |
| totalScore | INT | No | — | Gross score |
| adjustedGrossScore | INT | Yes | — | ESC-capped score |
| totalNet | INT | Yes | — | Net score |
| coursePar | INT | No | — | Course par |
| scoreVsPar | INT | No | — | +5, -2, etc. |
| scoreDifferential | REAL | Yes | — | WHS differential |
| handicapBefore | REAL | Yes | — | HI before round |
| handicapAfter | REAL | Yes | — | HI after round |
| front9Score | INT | Yes | — | Front 9 total |
| back9Score | INT | Yes | — | Back 9 total |
| notes | TEXT | Yes | '' | User notes |
| syncId | TEXT | Yes | — | Legacy |
| isSynced | BOOL | Yes | false | Cloud sync flag |
| useForAnalytics | BOOL | Yes | true | Include in HI calc |
| playedAt | DATETIME | Yes | now() | Round date |
| createdAt | DATETIME | Yes | now() | |
| updatedAt | DATETIME | Yes | now() | |

#### HoleScores
Per-hole scores within a round.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| roundId | INT | No | — | FK to Rounds |
| holeNumber | INT | No | — | 1-18 |
| par | INT | No | — | Hole par |
| score | INT | No | — | Gross strokes |
| yardage | INT | Yes | — | Hole yardage |
| putts | INT | Yes | — | Putts taken |
| fairwayHit | TEXT | Yes | — | 'Hit', 'Left', 'Right' |
| penalties | INT | Yes | — | Penalty strokes |
| groupRoundId | INT | Yes | — | FK to GroupRounds |
| participantId | TEXT | Yes | — | Group participant UID |
| isSynced | BOOL | No | false | Cloud sync flag |
| gir | BOOL | Yes | — | Green in regulation |

---

### 1.2 Social & Group Tables

#### Friends
Social graph connections.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| userId | TEXT | No | — | User UID |
| friendId | TEXT | No | — | Friend UID |
| friendName | TEXT | Yes | — | Denormalized |
| friendAvatar | TEXT | Yes | — | Denormalized |
| supabaseId | TEXT | Yes | — | Cloud UUID |
| isCoach | BOOL | Yes | false | Is a coach |
| isStudent | BOOL | Yes | false | Is a student |
| addedAt | DATETIME | Yes | now() | |
| **Unique**: (userId, friendId) |

#### GroupRounds
Multi-player round sessions.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| roundCode | TEXT UNIQUE | No | — | 6-char join code |
| captainId | TEXT | No | — | Creator UID |
| courseId | INT | No | — | FK to Courses |
| status | TEXT | Yes | 'PENDING' | PENDING, IN_PROGRESS, COMPLETED, CERTIFIED |
| scoringMode | TEXT | Yes | 'INDIVIDUAL_DEVICES' | Scoring method |
| useForAnalytics | BOOL | Yes | true | Include in HI |
| createdAt | DATETIME | Yes | now() | |
| updatedAt | DATETIME | Yes | now() | |

#### GroupRoundParticipants
Players in a group round.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| groupRoundId | INT | No | — | FK to GroupRounds |
| userId | TEXT | No | — | Player UID |
| status | TEXT | Yes | 'JOINED' | JOINED, READY, SCORING, DONE |
| role | TEXT | Yes | 'player' | player, captain |
| joinedAt | DATETIME | Yes | now() | |

---

### 1.3 Practice Tables

#### PracticeSessions
Driving range / practice sessions.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| userId | TEXT | No | — | User UID |
| supabaseId | TEXT | Yes | — | Cloud UUID |
| startTime | DATETIME | Yes | now() | Session start |
| endTime | DATETIME | Yes | — | Session end |
| locationName | TEXT | Yes | — | Range name |
| totalBalls | INT | Yes | 0 | Balls hit |
| sessionType | TEXT | Yes | 'FREE' | FREE, DRILL, COACH_ASSIGNED |
| drillId | INT | Yes | — | FK to Drills |
| coachDrillId | TEXT | Yes | — | Supabase UUID |
| targetDistance | INT | Yes | — | Target yards |
| notes | TEXT | Yes | — | User notes |
| createdAt | DATETIME | Yes | now() | |
| **Unique**: supabaseId |

#### PracticeShots
Individual shot records.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| sessionId | INT | No | — | FK to PracticeSessions |
| supabaseId | TEXT | Yes | — | Cloud UUID |
| clubId | INT | Yes | — | FK to Clubs |
| distance | REAL | Yes | — | Yards |
| quality | TEXT | Yes | — | great, good, okay, miss |
| shotShape | TEXT | Yes | — | straight, draw, fade, hook, slice |
| ballFlightJson | TEXT | Yes | — | AI-extended flight data |
| videoUrl | TEXT | Yes | — | Recorded video |
| poseMetricsJson | TEXT | Yes | — | MLKit pose data |
| timestamp | DATETIME | Yes | now() | |

#### Drills
Drill templates (5 built-in + user/coach custom).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| userId | TEXT | Yes | — | Creator (null = system) |
| name | TEXT | No | — | Drill name |
| description | TEXT | No | — | Description |
| category | TEXT | Yes | 'General' | General, Putting, Chipping, Full Swing, Bunker |
| difficulty | TEXT | No | — | Beginner, Intermediate, Advanced |
| durationMinutes | INT | No | — | Est. duration |
| icon | TEXT | Yes | 'target' | Icon identifier |
| isCustom | BOOL | Yes | false | User-created |
| supabaseId | TEXT | Yes | — | Cloud UUID |

#### DrillSteps
Step-by-step drill instructions.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| drillId | INT | No | — | FK to Drills |
| stepOrder | INT | No | — | Sequence |
| instruction | TEXT | No | — | Step text |
| targetDistance | INT | Yes | — | Target yards |
| ballsRequired | INT | No | — | Balls for this step |
| clubType | TEXT | Yes | — | Recommended club |

---

### 1.4 Marketplace Tables

#### Providers
Extended profile for Coach/Caddie roles.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| userId | TEXT UNIQUE | No | — | FK to UserProfiles.uid |
| role | TEXT | No | — | coach, caddie |
| name | TEXT | No | — | Display name |
| avatarUrl | TEXT | Yes | — | Photo URL |
| phone | TEXT | No | — | Phone number |
| whatsapp | TEXT | Yes | — | WhatsApp number |
| experience | INT | Yes | 0 | Years |
| coursesJson | TEXT | Yes | '[]' | Known courses |
| specializationsJson | TEXT | Yes | — | Specialties |
| availabilityJson | TEXT | Yes | '{}' | Availability schedule |
| price | REAL | Yes | — | Fee (KES) |
| rating | REAL | Yes | 5.0 | Average rating |
| totalReviews | INT | Yes | 0 | Review count |
| totalBookings | INT | Yes | 0 | Booking count |
| totalCalls | INT | Yes | 0 | Contact count |
| isAvailable | BOOL | Yes | true | Online status |
| profileComplete | BOOL | Yes | false | Full profile |
| certificationUrl | TEXT | Yes | — | Cert file URL |
| certificatesJson | TEXT | Yes | '[]' | Multiple certs |
| bio | TEXT | Yes | — | Bio/description |
| personalityType | TEXT | Yes | — | Coaching style |
| coachingLocation | TEXT | Yes | — | Location |
| coachingStylesJson | TEXT | Yes | — | Style tags |
| sessionTypesJson | TEXT | Yes | — | Session types |
| hasCertification | BOOL | Yes | false | Has cert |
| certificationName | TEXT | Yes | — | Cert name |
| targetAudienceJson | TEXT | Yes | — | Audience tags |
| views | INT | Yes | 0 | Profile views |
| streak | INT | Yes | 0 | Activity streak |
| createdAt | DATETIME | Yes | now() | |

#### Interactions
Player-provider contact logs.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| playerId | TEXT | No | — | Player UID |
| providerId | TEXT | No | — | Provider UID |
| type | TEXT | No | — | CALL, WHATSAPP |
| status | TEXT | Yes | 'pending' | pending, confirmed, dismissed |
| lastPromptedAt | DATETIME | Yes | — | Last booking prompt |
| timestamp | DATETIME | Yes | now() | |

#### Reviews
Provider ratings and reviews.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| providerId | TEXT | No | — | Provider UID |
| playerId | TEXT | No | — | Reviewer UID |
| playerName | TEXT | No | — | Denormalized |
| playerAvatar | TEXT | Yes | — | Denormalized |
| rating | INT | No | — | 1-5 |
| comment | TEXT | No | — | Review text |
| createdAt | DATETIME | Yes | now() | |

#### Bookings
Caddie service bookings.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| serverId | TEXT UNIQUE | Yes | — | Cloud UUID |
| playerId | TEXT | No | — | Player UID |
| providerId | TEXT | No | — | Caddie UID |
| roundType | TEXT | Yes | 'EIGHTEEN_HOLES' | EIGHTEEN_HOLES, FRONT_NINE, BACK_NINE |
| status | TEXT | Yes | 'PENDING' | PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED |
| initiatedVia | TEXT | Yes | 'CHAT' | CALL, CHAT |
| startTime | DATETIME | Yes | — | Booking start |
| endTime | DATETIME | Yes | — | Booking end |
| durationMinutes | INT | Yes | — | Duration |
| amountPaid | REAL | Yes | — | Payment amount |
| currency | TEXT | Yes | 'KES' | Currency |
| paymentMethod | TEXT | Yes | — | CASH, MPESA, CARD |
| createdAt | DATETIME | Yes | now() | |
| updatedAt | DATETIME | Yes | now() | |

#### Messages
Player-provider chat messages.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| serverId | TEXT UNIQUE | Yes | — | Cloud UUID |
| bookingId | TEXT | Yes | — | Related booking |
| senderId | TEXT | No | — | Sender UID |
| receiverId | TEXT | No | — | Receiver UID |
| content | TEXT | No | — | Message text |
| createdAt | DATETIME | Yes | now() | |
| readAt | DATETIME | Yes | — | Read timestamp |

#### Inquiries
Non-booking service inquiries.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INTEGER PK AUTO | No | — | Local PK |
| serverId | TEXT UNIQUE | Yes | — | Cloud UUID |
| playerId | TEXT | No | — | Player UID |
| providerId | TEXT | No | — | Provider UID |
| initiatedVia | TEXT | No | — | CALL, CHAT |
| status | TEXT | Yes | 'PENDING' | PENDING, RESOLVED |
| createdAt | DATETIME | Yes | now() | |

---

## 2. Supabase (PostgreSQL) Schema

### Connection
- **URL**: `https://qqvzklonfybticckpuvx.supabase.co`
- **Auth**: PKCE flow (deep link callback)

### Supabase Tables (25+)
The cloud schema mirrors the local schema with PostgreSQL types. Key differences:
- UUID-based IDs (vs auto-increment integers)
- JSONB for JSON fields
- Rich foreign key relationships
- Row Level Security policies

| Table | Local Equivalent | Key Differences |
|-------|------------------|-----------------|
| User | UserProfiles | UUID id, JSONB fields |
| Course | Courses | UUID id, city/region separate |
| Tee | Tees | UUID id, FK to Course |
| CourseHole | CourseHoles | UUID id, FK to Course + Tee |
| Round | Rounds | UUID id, FK to User + Course |
| HoleScore | HoleScores | UUID id, FK to Round |
| GroupRound | GroupRounds | UUID id (vs auto) |
| GroupRoundParticipant | GroupRoundParticipants | Same |
| GroupRoundScore | (realtime only) | Live scoring |
| Booking | Bookings | UUID id |
| Message | Messages | UUID id |
| Inquiry | Inquiries | UUID id |
| Friend | Friends | Status field, timestamps |
| Review | Reviews | UUID id |
| Notification | — | Push notifications |
| PlayerStat | (computed) | Aggregated stats |
| coaching_sessions | — | UUID id, FK to User |
| session_occurrences | — | UUID id, FK to coaching_sessions |
| session_enrollments | — | UUID id, FK to sessions + User |
| session_attendance | — | UUID id, FK to occurrences |
| drills | Drills | UUID id, creator_id |
| drill_steps | DrillSteps | UUID id |
| drill_assignments | — | Coach → player drill assignment |

### Supabase Realtime Subscriptions

| Channel | Tables | Purpose |
|---------|--------|---------|
| Booking changes | Booking | Live booking status updates |
| Messages | Message | Real-time chat |
| GroupRoundScore | GroupRoundScore | Live group round scoring |
| User profile | User | Cross-device profile sync |

### Supabase RPC Functions

| Function | Purpose | Parameters |
|----------|---------|------------|
| `create_coaching_session` | Atomic session + occurrence creation | p_coach_id, p_name, p_description, p_max_players, p_price_per_session, p_duration_minutes, p_location, p_days_of_week, p_start_time, p_weeks, p_start_date, p_payment_terms, p_session_type, p_location_area, p_target_skill_level, p_prerequisites, p_cancellation_policy |
| `update_coaching_session` | Session update with schedule regen | Same + p_session_id |
| `cancel_coaching_session` | Cancel + upcoming occurrences | p_session_id, p_coach_id |
| `enroll_player_in_session` | Enrollment with capacity check | p_session_id, p_player_id |
| `record_payment` | Payment recording | p_enrollment_id, p_amount, p_method |
| `complete_occurrence` | Mark session as completed | p_occurrence_id |
| `delete_user_account` | Full account deletion | — |
| `refresh_session_statuses` | Maintenance: update statuses | — |

### Storage Buckets

| Bucket | Purpose | Visibility |
|--------|---------|------------|
| `user_assets` | Profile photos, certifications, practice videos | Authenticated users |

Path patterns:
- Profile photos: `users/{uid}/profile/`
- Certifications: `users/{uid}/certifications/`
- Practice videos: `users/{uid}/practice_videos/`
- Club photos: `users/{uid}/club_photos/`

---

## 3. Migration Strategy

### Drift Migrations (v46 → v51)
The database currently handles migrations from version 46 through 51. Key migration steps:

- **v46**: Added `gir` column to HoleScores
- **v47**: Added `averageDistance` to Clubs, Course table recreation
- **v48**: Renamed `firestore_id` → `supabase_id` across all tables
- **v49**: Added `participantId`, `groupRoundId` to HoleScores
- **v50**: Added `useForAnalytics` to Rounds
- **v51**: Added `useForAnalytics` to GroupRounds

### Supabase Migrations
30 SQL migration files in `/supabase/migrations/` manage the cloud schema evolution.

### Sync Architecture
```
┌─────────────┐     push (idempotent upsert)     ┌─────────────┐
│  Drift/SQLite │ ──────────────────────────────→ │   Supabase   │
│  (Source of   │ ←────────────────────────────── │  (PostgreSQL)│
│   Truth)      │   pull (paginated, deduped)      │              │
└─────────────┘                                    └─────────────┘
     ↑                                                    ↑
     │ watch() streams                                    │ realtime subscriptions
     ↓                                                    ↓
  Riverpod Providers                               UI Updates
```

**Sync triggers:**
1. App start (immediate)
2. Every 10 seconds while authenticated (SyncController timer)
3. Network connectivity restored
4. Manual pull-to-refresh on Dashboard
