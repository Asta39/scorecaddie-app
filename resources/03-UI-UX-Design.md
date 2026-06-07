# ScoreCaddie — UI/UX Design Document

## 1. Design System

### Brand Identity
- **Primary Color**: Emerald 700 (`#1B7A4E`) — Trust, nature, golf greens
- **Accent Color**: Golf Lime (`#A3E635`) — Energy, action, CTA
- **Glass accents**: Golf Sand (`#C2B280`), Golf Sky (`#0EA5E9`), Golf Purple (`#A855F7`)

### Typography
- **Family**: Inter (Google Fonts)
- **Weights**: 500 (Medium), 600 (SemiBold), 700 (Bold), 800 (ExtraBold), 900 (Black)
- **Scale**: 9px (labels) → 11px (section headers) → 12-14px (body) → 16-18px (titles) → 24-28px (hero text)

### Theme Modes
- **Light Mode**: White backgrounds (`#FFFFFF`), grey-900 text, emerald accents
- **Dark Mode**: Grey-900 backgrounds, white text, lime accents
- **System default**: Follows device preference

### Component Library

#### GlassCard (`lib/core/theme/glass_card.dart`)
Used throughout for cards, containers, and the bottom nav bar. Characterized by:
- Semi-transparent white background (0.92 alpha)
- Subtle border (grey-200, 0.4 alpha)
- Soft shadow (grey-900, 0.08 alpha, 30px blur)
- Rounded corners (20-35px radius)

#### FloatingGlassNavBar
- Height: 70px
- Border radius: 35px (pill shape)
- Frosted glass effect: white 0.92 alpha + layered shadows
- Home tab uses app logo icon
- Other tabs use Lucide icons
- 3 variants (6, 6, 3 tabs depending on role)

#### Buttons
| Type | Height | Radius | Style |
|------|--------|--------|-------|
| FilledButton | 56px | 20px | Emerald-700 bg, white text, w800 |
| OutlinedButton | 56px | 20px | Transparent bg, emerald border (2px), w800 |
| TextButton | auto | auto | Emerald-700 text, w700 |

#### Score Badge Colors
| Score vs Par | Color | Hex |
|-------------|-------|-----|
| Eagle or better | Amber | `#F59E0B` |
| Birdie | Blue | `#3B82F6` |
| Par | Emerald | `#10B981` |
| Bogey | Orange | `#F97316` |
| Double Bogey | Red | `#EF4444` |
| Worse | Dark Red | `#991B1B` |

## 2. Screen Catalogue

### Auth & Onboarding (6 screens)

#### SplashScreen (`/splash`)
- Animated logo display
- Auto-navigates after animation completes
- No user interaction required

#### AuthScreen (`/auth`)
- **iOS-style onboarding** with multiple carousel pages
- App description slides (golf imagery)
- **CTA rows**: "Continue with Email" / "Continue with Google"
- Terms & Privacy Policy links at bottom
- Clean, minimal, white background

#### RoleSelectionScreen (`/select-role`)
- 3 large option cards: **Player**, **Coach**, **Caddie**
- Each with icon, title, brief description
- "Continue" button after selection
- Role determines entire app experience thereafter

#### PlayerOnboardingScreen (`/player-onboarding`)
- Profile photo upload (with face verification option)
- Name entry
- Home course selector (dropdown of 17 courses)
- Handicap origin picker: new_golfer / self_reported / kgu_verified
- Initial handicap entry (if self_reported)
- Units preference: Yards / Meters

#### ProviderOnboardingScreen (`/provider-onboarding`)
- Same base profile fields
- Phone / WhatsApp numbers
- Experience (years)
- Course specializations (multi-select)
- Certification upload
- Bio / description
- Price setting

#### LoadingTransitionScreen (`/loading`)
- Circular progress indicator
- Used between auth → home during data initialization

### Shell Routes (Bottom Nav)

#### AppShell (`/` base)
- **3 role-specific tab configurations:**
  - **Player**: Home | Practice | Stats | Caddie | Leaderboard | Profile
  - **Coach**: Home | Sessions | Students | Drills | Payments | Profile
  - **Caddie**: Home | Payments | Profile
- Floating glass nav bar at bottom
- SafeArea top padding
- Sync indicator on home tab
- Completed booking prompts (rating dialog)

#### DashboardScreen (`/`)
- **Role-aware routing**: PlayerDashboardView | CoachDashboardScreen | CaddieHomeScreen

**Player Dashboard:**
- Top header: Time-based greeting, user name, profile photo
- Sync button (top right)
- Weekly calendar strip (7-day, today highlighted)
- "START ROUND" CTA button (large lime card with play icon)
- Streak widget
- Performance grid: Handicap Index, Avg Score, Total Rounds, Best Round
- Past Activities list (last 3 rounds with course logo, date, score)
- Pull-to-refresh for sync

**Coach Dashboard:**
- Upcoming sessions overview
- Active students count
- Recent enrollments
- Revenue summary

**Caddie Home:**
- Active bookings
- Current round status
- Availability toggle

### Scorecard & Rounds (9 screens)

#### CourseSelectScreen (`/select-course`)
- List of all courses (17 Kenyan seeded + user-added)
- Course logos fetched via `CourseLogoHelper`
- Search bar
- Location-based sorting (nearest first)
- "Add Course" option at bottom

#### CourseIntelScreen (`/scorecard/intel/:id`)
- Course overview: logo, name, location, par, yardage
- Hole-by-hole breakdown grid
- Previous rounds on this course (personal best)
- "Start Round" button with tee selection modal
- Tee box selector with rating/slope info

#### RoundSetupModal (inline sheet)
- Hole count selector: 9 / 18
- Tee box selection (from course tees)
- Course handicap calculation display
- Playing partners option (for group rounds)

#### ScoringScreen (`/scoring`)
- **Hole-by-hole input card**
- Current hole number indicator
- Score input (stepper: + / -)
- Putts input
- Fairway hit: left / hit / right
- GIR toggle
- Penalties count
- Yardage display from course data
- Running total score vs par
- Navigation: previous hole / next hole
- "End Round" button at 18th hole

#### GroupScoringScreen (`/group-scoring`)
- Same hole-by-hole input as solo
- Plus: live scores of other players in group
- Player cards with avatar, name, current score
- Real-time updates via Supabase Realtime
- Captain certification flow

#### GroupCertificationScreen (`/group/certification/:id`)
- Full round summary for all participants
- Captain reviews each player's scores
- "Certify" button finalizes all scores
- Once certified, scores pushed to rounds permanently

#### RoundDetailScreen (`/round/:roundId`)
- Header: course name, date, total score vs par
- Handicap impact: before/after index
- Score differential display
- Hole-by-hole breakdown table
- Stats summary: fairways hit, GIR, putts, penalties
- "Share" button for highlight card
- "Edit" option for corrections

#### RoundsHistoryScreen (`/rounds-history`)
- Chronological list of all completed rounds
- Filter by course, date range, score range
- Each item: course logo, name, date, score, vsPar

#### CourseProfileScreen (linked from rounds)
- Course stats for user: best score, avg score, total rounds
- Score distribution chart
- Best/worst holes

### Practice (6 screens)

#### PracticeRangeScreen (`/practice`)
- Main practice hub
- "Free Practice" button
- Drill library (built-in + custom)
- Recent practice sessions summary
- Voice logger entry point

#### PracticeSessionScreen (`/practice/session/:id`)
- Active practice session
- Shot logging interface:
  - Manual: club selector, distance, shape, quality
  - Voice: microphone button → transcription → extraction
- AI Caddie "Daniel" orb (voice orb visualizer)
- Drill mode: displays drill steps
- Session timer

#### SessionSummaryScreen (`/practice/summary/:id`)
- Total balls hit
- Club performance breakdown
- AI analysis from Gemini
- Coaching feedback from Daniel
- Share summary option

#### PracticeAnalyticsScreen (`/practice/analytics`)
- Aggregated practice stats
- Club performance trends
- Shot dispersion charts (if distance tracked)
- Drill completion metrics

#### CustomDrillBuilderScreen (`/practice/drills/new`)
- Drill name, description
- Category, difficulty selector
- Duration input
- Step-by-step creator (add steps with instruction, balls, distance)
- Club type per step

#### VoiceLoggerScreen (`voice-logger`)
- Microphone button (record → transcribe → extract)
- Transcript preview
- Extracted shot data confirmation
- Manual correction option
- "Daniel" orb for AI feedback after logging

### Marketplace (5 screens)

#### CaddieMarketplaceScreen (`/caddie`)
- Grid/list of available caddies
- Filter by: location, specialization, rating, price
- Sort by: rating, experience, price
- Each card: photo, name, rating, price, experience years

#### ProviderPreviewScreen (`/marketplace/provider/:id`)
- Full provider profile
- Photo, name, role (Caddie/Coach)
- Bio, experience, specializations
- Courses they know
- Certifications
- Rating breakdown
- Reviews list
- "Contact" button (WhatsApp deep link)
- "Book" button → creates inquiry/booking

#### CoachPublicSessionsScreen (`/marketplace/coach/:coachId/sessions`)
- List of coach's public sessions
- Each: name, description, schedule (days/time), price, capacity
- "Enroll" button per session

#### SessionBookingScreen (`/marketplace/coach/:coachId/session/:sessionId/book`)
- Session details summary
- Player info pre-filled
- Payment method selector (Cash / M-Pesa / Card)
- Terms acceptance
- "Confirm Enrollment" button

#### PlayerSessionDetailsScreen (`/coaching/session/:id`)
- Player's enrolled session view
- Upcoming occurrences
- Attendance history
- Coach contact info
- Assigned drills

### Provider Screens (13 screens)

#### CaddieHomeScreen (`/caddie/home`)
- Active bookings list
- Status: PENDING / CONFIRMED / IN_PROGRESS
- "Mark as In Progress" / "Mark as Complete" actions

#### CaddieDashboardScreen (role variant)
- Earnings summary
- Completed rounds count
- Rating
- Upcoming bookings

#### CaddiePaymentsScreen (`/caddie/payments`)
- Payment history
- Amounts, methods, dates
- Total earned

#### CaddieRoundsScreen (`/caddie/rounds`)
- Rounds caddied
- Course, date, player, earnings

#### CoachDashboardScreen (`/` coach view)
- Sessions overview
- Student count
- Revenue summary
- Recent activity

#### CoachSessionsScreen (`/coach/sessions`)
- List of created sessions
- Status filter: active, pending, completed
- Create new session FAB

#### CreateSessionScreen (`/create-session`)
- Session name, description
- Session type: Group / Individual
- Max players
- Price per session
- Duration (minutes)
- Location + Location area
- Days of week (multi-select)
- Start time
- Duration in weeks
- Target skill level
- Prerequisites, cancellation policy
- Payment terms (upfront / per-session)

#### EditSessionScreen (`/coach/session/:id/edit`)
- Same form as create, pre-filled

#### SessionDetailsScreen (`/coach/session/:id`)
- Session info
- Enrolled players list
- Occurrences timeline
- Attendance tracking per occurrence
- Mark occurrence in-progress → complete
- Student list with drill assignment

#### CoachStudentsScreen (`/coach/students`)
- All enrolled students across sessions
- Student profile quick view
- Session attendance history
- Assignment of drills

#### CoachDrillsScreen (`/coach/drills`)
- Drill template library
- Create new drill
- Assign drills to students

#### CoachDrillBuilderScreen (`/coach/drills/new`)
- Same as CustomDrillBuilderScreen

#### CoachPaymentManagementScreen (`/coach/payments`)
- Revenue breakdown by payment method
- Student-wise payment status
- Record payment modal

### Social (5 screens)

#### FriendsScreen (`/profile/friends`)
- Friends list with avatars + names
- Friend requests (incoming/outgoing)
- "Add Friend" by UID
- Search friends

#### LeaderboardScreen (`/leaderboard`)
- Tab bar: Global | Friends | Course
- Player rank, name, handicap index, rounds count
- Current user highlighted

#### PlayerProfileScreen (`/player/:id`)
- User display: avatar, name, handicap
- Recent rounds
- Stats overview
- "Add Friend" button

#### ChatScreen (`/chat/:id`)
- Real-time messaging via Supabase Realtime
- Message bubbles, timestamps
- Text-only (no media yet)

#### GroupRoundLobbyScreen (`/round/lobby/:id`)
- Round code display (for sharing)
- Participants list with status
- "Start Round" button (captain only)
- QR code for join

### Profile (4 screens)

#### ProfileScreen (`/profile`) (1,768 lines)
- Avatar with photo picker + face verification
- Name, email, role
- Handicap display with WHS breakdown (rounds used, trend)
- Home course
- Skill level, preferred tees, play style
- Units toggle
- Privacy level
- Golf bag management link
- Badges/achievements display
- Settings link
- Help & Support

#### SettingsScreen (`/profile/settings`)
- Theme mode: Light / Dark / System
- Notification preferences
- Account management

#### ClubsScreen (`/profile/bag`)
- Club list with type, brand, model, loft
- Add club (type, brand, model, distance, loft)
- Average distance tracking

#### HelpScreen (`/help`)
- FAQ
- Contact support
- App version

### Analytics & Achievements (2 screens)

#### AnalyticsScreen (`/analytics`)
- Overview: rounds, scoring average, best round
- Handicap trend chart
- Score distribution chart
- Fairway hit % pie/bar
- GIR % display
- Putting average
- Course-specific breakdowns

#### AchievementsGalleryScreen (`/achievements`)
- Grid of 50 achievements across 5 categories
- Locked vs unlocked states
- Progress indicators per category
- Points/score display

## 3. Navigation Patterns

### Deep Links
- `scorecaddie://login-callback` — OAuth callback
- `/round/join/{code}` — Shareable group round join
- `/friend/add/{uid}` — Shareable friend invite
- `/marketplace/provider/{id}` — Shareable provider profile
- `/player/{id}` — Shareable player profile

### Modal vs Push
| Navigation | Pattern | Used For |
|-----------|---------|----------|
| Full-screen push | context.push() | New flows (scoring, practice, details) |
| Sheet (bottom) | showModalBottomSheet | Tee selection, round setup, booking confirmation |
| Dialog | CupertinoAlertDialog | Booking confirmation prompts, rating reminder |
| Push (shell routes) | pageBuilder with NoTransitionPage | Bottom nav tabs |

## 4. Error & Empty States

### Loading States
- CircularProgressIndicator (emerald-700 colored)
- CupertinoActivityIndicator (iOS style)
- Shimmer/skeleton loading for lists (planned)

### Error States
- Red error text with message
- ConnectionGuard overlay for network failures
- AI service fallback messages for API failures

### Empty States
- "No rounds yet" for empty history
- "No tees found for this course" for missing course data
- "No friends yet" for empty social

## 5. Accessibility

- Minimum touch targets: 48px (buttons, nav items)
- Font scaling via Inter font family
- High contrast text (emerald/dark backgrounds)
- VoiceOver/TalkBack labels on all icon buttons
