# ScoreCaddie App Audit Report

## 1. Local Database & State

*   **Database Tables:** Drift/SQLite implementation is intact. No essential tables have been deleted. Tables like `Courses`, `Rounds`, `HoleScores`, `UserProfiles`, and `PracticeSessions` are correctly defined in `lib/core/database/database.dart`.
*   **Data Seeding:** The `seedCourses` logic exists in `lib/core/database/seed_courses.dart` and properly inserts 17 Kenyan golf courses into the database with pars and `teeData` yardages, and is successfully called during app initialization in `main.dart`.
*   **Data Flow Issue:** The primary reason the "total yardage fields haven't been populated" is due to a data flow issue in `lib/screens/scorecard/scoring_screen.dart`. When loading course data, `_holeYardages` is populated with a default array of zeroes (`List.filled(activePars.length, 0)`). The app fails to parse the `teeData` JSON string from the `Course` object to extract the yardages for the selected `tee` to populate the `_holeYardages` state.

## 2. WHS Engine & Handicap Logic

*   **WHS Engine Implementation:** The handicap calculation logic exists in `lib/core/utils/handicap.dart`. It correctly utilizes a simplified WHS-inspired formula (averaging the best differentials out of the last 20 rounds).
*   **Round Flow Logic:** The `ScoringScreen` captures the correct data required for WHS handicap calculation (including advanced stats like putts, fairways, and penalties) and properly saves them to the database.

## 3. UI/UX & Status Bar Blinding Issue

*   **The Problem:** The app's status bar is "blinded" across many screens due to the hardcoded `AnnotatedRegion<SystemUiOverlayStyle>` configurations.
*   **Root Cause:**
    *   In `lib/app.dart`, the `MaterialApp.builder` wraps the entire app in a hardcoded white status bar (`statusBarColor: Colors.white`, `statusBarIconBrightness: Brightness.dark`), overriding native transparent behaviors.
    *   Several screens (e.g., `RoleSelectionScreen`, `AuthScreen`, `ProviderOnboardingScreen`) explicitly force `SystemUiOverlayStyle.dark`.
    *   Some screens lack `SafeArea` widgets around their main `Scaffold` body, causing content to render underneath the rigid status bar.

## 4. Security Audit

*   **Firebase Security Rules:** The provided Firestore rules are reasonably well-structured:
    *   Users have exclusive read/write access to their private profiles and friend data.
    *   Friend requests are accessible to authenticated users.
    *   Marketplace providers are globally readable but strictly isolated to the owner for writes.
    *   Profiles are readable for search purposes, but only writeable by the owner.
*   **Local Database Security:** No raw SQL injection vulnerabilities were detected. All local Drift queries utilize safe parameterized expressions (e.g., `.where((c) => c.userId.equals(userId))`). Firestore queries correctly use the parameterized `where('key', isEqualTo: value)`.

## 5. Feature Gap Analysis

*   **Current State:** The codebase successfully embodies almost all elements of the overarching vision. The `screens/` directory contains functional modules for the `scorecard`, `marketplace`, role-based dashboards, `social` (leaderboard/friends), and a robust `practice` range with AI shot analysis.
*   **Gap/Next Steps:** The core gap lies in data piping (yardages not populating in the scoring screen) and UI/UX polish (resolving the global status bar overlap issue across all scaffolds).

## Recommended Next Steps Before Coding New Features

1.  **Fix Status Bar Visibility:** Refactor `app.dart` to use `SystemUiOverlayStyle(statusBarColor: Colors.transparent)` and ensure `SafeArea` is properly applied to screens like `RoleSelectionScreen`.
2.  **Populate Yardage Data:** Update `_loadCourseData` in `ScoringScreen` to parse the `course.teeData` JSON based on the `widget.tee` and populate `_holeYardages` accordingly so the UI displays the correct lengths.
