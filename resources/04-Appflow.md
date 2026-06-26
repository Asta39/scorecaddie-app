# ScoreCaddie — Application Flow Document

## 1. Master Navigation Flow

```
App Launch → SplashScreen (animation)
  ├─ Logged Out → AuthScreen (email / Google)
  │                ├─ Email Register → RoleSelectionScreen
  │                ├─ Email Login → Dashboard (profile exists)
  │                └─ Google Login → RoleSelectionScreen (new user)
  │
  ├─ Logged In, No Profile → RoleSelectionScreen
  │                           ├─ Player → PlayerOnboardingScreen → Dashboard
  │                           ├─ Coach → ProviderOnboardingScreen → Dashboard
  │                           └─ Caddie → ProviderOnboardingScreen → Dashboard
  │
  └─ Logged In, Complete Profile → Dashboard (role-based)
```

## 2. Authentication Flow

### 2.1 Email/Password Sign-Up
```
AuthScreen → "Sign Up" tab → Email + Password + Confirm Password
  → SupabaseAuthService.registerWithEmail()
  → AuthState stream emits AuthUser
  → RouterNotifier detects logged in, profile null
  → Redirect to /select-role
```

### 2.2 Google Sign-In
```
AuthScreen → "Continue with Google"
  → SupabaseAuthService.signInWithGoogle() (PKCE OAuth)
  → Browser popup → Google consent
  → Callback to scorecaddie://login-callback
  → AuthState stream emits AuthUser
  → Same redirect as email
```

### 2.3 Profile Onboarding (Player)
```
RoleSelectionScreen → "Player" selected
  → PlayerOnboardingScreen:
    1. Upload photo (image_picker) → storage → avatarUrl
    2. Enter name
    3. Select home course (dropdown from Courses table)
    4. Select handicap origin
    5. Enter initial handicap (if self_reported)
    6. Select units (Yards/Meters)
  → ProfileService.ensureProfile() creates UserProfile record
  → profileComplete = true
  → RouterNotifier detects profile complete → redirect to /
```

### 2.4 Profile Onboarding (Coach/Caddie)
```
RoleSelectionScreen → "Coach" or "Caddie"
  → ProviderOnboardingScreen:
    1. All Player steps (photo, name, etc.)
    2. Phone / WhatsApp
    3. Experience years
    4. Course specializations
    5. Certification upload (storage)
    6. Bio / description
    7. Price
  → ProfileService.ensureProfile() creates UserProfile + Provider records
  → profileComplete = true
  → Redirect to /
```

## 3. Round Scoring Flow

### 3.1 Solo Round (18 or 9 holes)
```
Dashboard → "START ROUND" CTA
  → /select-course (CourseSelectScreen)
  → Tap course → /scorecard/intel/:id (CourseIntelScreen)
     → View hole-by-hole breakdown
     → Tap "Start Round" → RoundSetupModal
        → Select holes (9/18)
        → Select tee box
        → View course handicap calculation
        → "Start" button
  → /scoring (ScoringScreen)
     → For each hole (1-18 or 1-9):
        1. Display hole number, par, yardage, SI
        2. Input score (stepper or numpad)
        3. Input putts
        4. Select fairway hit (left/hit/right) — par 4+ only
        5. Toggle GIR
        6. Input penalties
        7. Show running total vs par
        8. "Next Hole" → save hole score to local DB
     → After final hole:
        → Calculate total score, AGS (ESC-capped), score differential
        → Save Round + HoleScores to local DB
        → Trigger WHS recalculation (handicapProvider updates)
        → HandicapTrackerProvider persists new HI + anchor to profile
        → SyncService syncs round to Supabase (async)
     → Navigate to /round/:id (RoundDetailScreen)
```

### 3.2 Group Round Flow
```
Captain flow:
  Dashboard → /select-course → select course → RoundSetupModal
  → Select "Group Round" mode
  → GroupSyncService.createGroupRound()
     → Creates GroupRound record (PENDING status)
     → Generates 6-character roundCode
     → Creates GroupRoundParticipant (captain, role='captain')
  → Captain shares roundCode via WhatsApp / link

Player join flow:
  → Tap shared link (scorecaddie://round/join/{code})
  → or enter code on /round/join/:code
  → JoinRoundHandleScreen:
     1. Lookup round by code in Supabase
     2. Show TeeSetupModal: select tee box
     3. GroupSyncService.joinGroupRound() → add participant
  → Redirect to /round/lobby/:id

Lobby flow:
  → All participants see:
     - Round code (displayed prominently)
     - Participant list with avatar + status (JOINED/READY)
     - Captain sees "Start Round" button
  → Captain taps "Start" → GroupRound status → IN_PROGRESS
  → All participants auto-navigate to /scoring?groupRoundId=xxx

Live scoring flow:
  → Each player scores on their own device (same UI as solo)
  → Each hole score pushed to Supabase Realtime
  → All other players see live updates in GroupScoringScreen
  → Hole-by-hole comparison cards for each participant

Certification flow:
  → After final hole, all participants get "Pending Certification" status
  → Captain navigates to /group/certification/:id
  → GroupCertificationScreen:
     - Review all participants' scores
     - Captain taps "Certify" button
     - GroupSyncService.certifyGroupRound()
        → For each participant: create Round + HoleScores in local DB
        → Mark as synced
        → GroupRound status → CERTIFIED
  → All participants get rounds in their history
```

### 3.3 Course Intel Flow
```
CourseSelectScreen → tap course
  → /scorecard/intel/:id
  → Load course data:
     1. Course name, location, region, city
     2. Logo asset (CourseLogoHelper)
     3. Total holes, par
     4. Tee boxes with rating/slope/yardage
     5. Hole-by-hole grid (hole #, par, SI, distance)
  → Load user's history on this course:
     - Best score, avg score, total rounds
     - Previous scores on this course
  → User tap "Start Round" → RoundSetupModal
```

## 4. AI Caddie Flow (Daniel)

### 4.1 Voice Shot Logger (Practice)
```
PracticeRangeScreen → "Voice Logger"
  → VoiceLoggerScreen
  → User taps microphone button
  → Starts recording (record package)
  → User speaks: "Hit my 7 iron about 150, slight fade"
  → User taps stop
  → Audio file sent to Groq Whisper: transcribe()
  → Transcript text sent to Groq Llama 3.1: extractShot()
  → Returns JSON: {club, distance, distance_confidence, shape, trajectory, quality, notes}
  → Display extracted shot to user for confirmation/correction
  → User confirms → save to PracticeShots table
  → 3+ shots accumulated → AICaddieService.getCoachingFeedback()
     → Sends recent shots to Llama 3.3 70B
     → Receives coaching text
     → If voice enabled: textToSpeech() via ElevenLabs → play audio via just_audio
     → Display coaching text on screen
  → Session continues until user ends
```

### 4.2 Practice Session Analysis
```
PracticeSessionScreen → "End Session"
  → Navigate to /practice/summary/:id
  → PracticeAnalysisService.analyzeSession():
     1. Collect all PracticeShots for session
     2. Aggregate club stats (count, quality %, avg distance, common shape)
     3. Gemini 1.5 Flash prompt with session data
     4. Returns "Session Verdict", "Struggling Club", "Pure Club", "Pro Tip"
  → Display AI analysis on SessionSummaryScreen
  → Option to save/share analysis
```

### 4.3 Performance Trend Analysis
```
AnalyticsScreen → "AI Analysis" button
  → PracticeAnalysisService.analyzePerformance():
     1. Collect aggregate stats: rounds, fairway%, GIR%, putts, score trend
     2. Gemini prompt with performance data
     3. Returns personalized coaching advice
  → Display in modal/dedicated section
```

## 5. Practice Range Flow

### 5.1 Free Practice
```
PracticeRangeScreen → "Free Practice"
  → Create PracticeSession (sessionType='FREE')
  → PracticeSessionScreen:
     - Shot logging mode (manual or voice)
     - Club selector (from user's Clubs table)
     - Distance input (yards)
     - Shape: straight / draw / fade / hook / slice
     - Trajectory: low / normal / high
     - Quality: great / good / okay / miss
     - "Log Shot" button → saves PracticeShot
     - Session timer running
     - Ball counter
  → "End Session" → calculate total balls, session duration
  → Navigate to SessionSummaryScreen
```

### 5.2 Drill Practice
```
PracticeRangeScreen → select drill (e.g., "Clock Face Drill")
  → Create PracticeSession with drillId reference
  → PracticeSessionScreen with drill overlay:
     - Current step displayed (e.g., "Step 1: Hit 5 balls to 12 o'clock")
     - Step progression (auto-advance after ball count met)
     - Same shot logging as free practice
  → End session → drill completion stats
```

### 5.3 Custom Drill Builder
```
PracticeRangeScreen → "Create Drill"
  → CustomDrillBuilderScreen:
     1. Name, description
     2. Category: General / Putting / Chipping / Full Swing / Bunker
     3. Difficulty: Beginner / Intermediate / Advanced
     4. Duration (minutes)
     5. Add steps:
        - Instruction text
        - Target distance
        - Balls required
        - Club type
     6. Save → insert Drills + DrillSteps to local DB
```

## 6. Marketplace & Booking Flow

### 6.1 Caddie Discovery
```
AppShell → "Caddie" tab → /caddie
  → CaddieMarketplaceScreen:
     - Load all Providers where role='caddie'
     - Display cards with photo, name, rating, experience, price
     - Filter: by course, by rating range, by price range
     - Sort: rating high-low, experience high-low, price low-high
  → Tap provider → /marketplace/provider/:id
     - ProviderPreviewScreen
     - View full profile, certifications, reviews
     - "Contact via WhatsApp" → url_launcher
     - "Book Caddie" → creates booking request
```

### 6.2 Booking Flow
```
ProviderPreviewScreen → "Book Caddie"
  → SupabaseService.createBooking():
     1. playerId = current user
     2. providerId = selected caddie
     3. status = PENDING
     4. roundType = EIGHTEEN_HOLES / FRONT_NINE / BACK_NINE
  → Booking appears on caddie's CaddieHomeScreen
  → Caddie sees all pending bookings
  → Caddie taps "Confirm" → status → CONFIRMED
  → Player notified (realtime subscription)
  → During round: caddie marks "In Progress"
  → After round: caddie or player marks "Completed"
  → Upon completion: rating prompt appears in AppShell
```

### 6.3 Interaction Logging
```
ProviderPreviewScreen → "Call" / "WhatsApp"
  → InteractionService.logCall() or logWhatsApp()
  → Creates Interaction record (playerId, providerId, type, status='pending')
  → After 2 hours, AppShell checks for pending interactions
  → Shows confirmation dialog: "Did you book {name}?"
     - "Yes, Booked" → creates Booking + marks interaction confirmed
     - "No, I didn't" → creates Inquiry + dismisses interaction
     - "Not Yet" → leaves pending for another 2 hours
```

### 6.4 Coaching Session Enrollment
```
CoachPublicSessionsScreen → select session
  → SessionBookingScreen:
     - Session details (name, schedule, price, capacity)
     - Player info (auto-filled from profile)
     - Payment method selector
     - "Confirm Enrollment"
  → CoachingService.enrollInSession():
     1. Calls Supabase RPC enroll_player_in_session (atomic, capacity check)
     2. Establishes bi-directional Friend contact (player ↔ coach)
  → Enrollment appears on PlayerSessionDetailsScreen
  → Coach sees new enrollment on SessionDetailsScreen
```

## 7. Social Flow

### 7.1 Friends
```
ProfileScreen → "Friends" → /profile/friends
  → FriendsScreen:
     - Friends list (avatars, names, handicap)
     - Friend requests tab (incoming / outgoing)
     - "Add Friend" button → enter UID or scan QR
     - FriendService.addFriend(uid)
     - If other user exists, creates Friend record (status='PENDING')
     - Other user sees request → tap "Accept" → status='ACCEPTED'
  → Tap friend → /player/:id → PlayerProfileScreen
     - View their stats, recent rounds, handicap
     - "Compare" option (planned)
```

### 7.2 Leaderboards
```
AppShell → "Leaderboard" tab → /leaderboard
  → LeaderboardScreen:
     - Tab 1: Global — all users ranked by handicap index
     - Tab 2: Friends — friends list ranked
     - Tab 3: Course — per-course leaderboard (best scores)
  → Each entry: rank, avatar, name, handicap, rounds count
  → Current user highlighted
```

### 7.3 Real-time Chat
```
Friend tile → "Message" → /chat/:id
  → ChatScreen:
     - Load conversation via Supabase Realtime subscription
     - Messages stream (senderId, receiverId, content, createdAt)
     - Input field + send button
     - Messages appear in real-time for both users
```

### 7.4 Group Round Lobby
```
/round/lobby/:id
  → Round code displayed (large, copy-able)
  → QR code for join (qr_flutter)
  → Participant cards:
     - Avatar, name, status (JOINED / READY)
     - Captain badge on round creator
  → Captain actions: "Start Round", "Share Code"
  → Non-captain actions: "Ready" toggle
```

## 8. Synchronization Flow

### 8.1 Auto-Sync Cycle
```
App launch:
  → SyncService.syncAllPending() called (AppShell._triggerSync)
  → Every 10 seconds: SyncController timer fires
  → Network connectivity changes: triggers sync

syncAllPending() flow:
  1. pullProfile() — download latest profile from Supabase (merged with local)
  2. pullProviders() — download provider profiles
  3. pullKguData() — paginated pull of Courses (1000/1000), Tees, Holes
  4. pullRounds() — restore rounds from cloud for cross-device
  5. syncProfile() — upload local profile changes
  6. _migrateCourses() — push unsynced courses to Supabase
  7. _migrateRoundsAndStats() — push unsynced rounds + PlayerStat
```

### 8.2 Conflict Resolution
- **Profile merging**: Role protection (never downgrade coach→player), name preservation
- **Course deduplication**: Before sync, clean up duplicate courses by name+location
- **Round idempotency**: Deterministic UUID v5 for hole scores prevents duplicates
- **Upsert semantics**: All Supabase writes use `onConflict: 'id'` for idempotent upserts
- **isSynced flag**: Records marked synced after successful cloud write

### 8.3 Offline Handling
- All core features work offline (scoring, history view, practice)
- Network calls wrapped in ConnectionGuard → shows OfflineBottomSheet on failure
- Pending records queued with `isSynced = false`
- Auto-sync fires on connectivity restored

## 9. Achievement Checking Flow
```
After each round completes:
  → AchievementService.checkAndUnlock():
     1. Check scoring achievements (break 100/90/80, first birdie/eagle)
     2. Check consistency (streaks, fairway%, GIR%)
     3. Check activity (round count milestones, 36 holes)
     4. Check explorer (course count milestones)
     5. Check social (friend count, share count)
     6. Check streak milestones (weekly streaks)
  → If new achievement unlocked: show AchievementDialog
  → Update badgesJson on UserProfile

After each practice session:
  → Check practice-related achievements (if any)

On app launch:
  → Re-check all achievements (idempotent — detects if already unlocked)
```

## 10. Sync & Connectivity States

### State Machine: SyncService
```
IDLE → syncing → syncAllPending() → callback ✓ → IDLE
                             ↓ error
                         RETRY (on next cycle or connectivity change)

States:
  - IDLE: sync timer waiting
  - SYNCING: _isSyncing = true (prevents concurrent syncs)
  - ERROR: caught, logged, next cycle retries
```

### State Machine: ConnectionGuard
```
ONLINE → network call → SUCCESS → continue
                   ↓ SocketException → show OfflineBottomSheet
                                     → retry button → retry call
                                     → dismiss → continue offline
OFFLINE → connectivity change → retry pending calls
```

## 11. Error Handling Flows

| Scenario | Handling |
|----------|----------|
| Network failure during sync | SocketException caught, retry on next cycle |
| AI service timeout | Fallback message displayed |
| Auth token expired | Auto-refresh via Supabase PKCE |
| DB migration error | Caught in onUpgrade, column creation wrapped in try/catch |
| Course not found on Supabase | Skips round sync (logged) |
| Duplicate course on insert | Upsert with unique constraint handling |
| Provider profile missing | Safe null handling with defaults |
