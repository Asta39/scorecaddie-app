<div align="center">
  <img src="assets/logo.png" alt="ScoreCaddie Logo" width="200"/>
  <h1>ScoreCaddie Player App ⛳</h1>
  <p>The ultimate digital caddie and club management application for golfers.</p>
</div>

---

## 📖 Overview

**ScoreCaddie** is a comprehensive mobile application built with **Flutter** and powered by **Supabase**. It provides golfers with a seamless experience for tracking their game, interacting with their club, and managing tee times.

### 🌟 Key Features

- **Live Scoring & Leaderboards:** Enter scores hole-by-hole and watch the live leaderboard update in real-time.
- **Tee Time Management:** Automatically generated starting sheets and a Preferred Time Window system for effortless booking.
- **Club News Feed:** Stay up to date with the latest announcements, fixture updates, and result highlights directly from your club admin.
- **Push Notifications:** Powered by OneSignal for instant tee time reminders and club alerts.
- **Social & Friends:** Add friends, compare handicaps, and coordinate group rounds easily.

## 🛠 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend as a Service:** [Supabase](https://supabase.com/)
  - Postgres Database
  - Realtime subscriptions
  - Edge Functions (Deno)
  - Row Level Security (RLS)
- **Push Notifications:** [OneSignal](https://onesignal.com/)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.0.0+)
- Dart (v3.0.0+)
- A Supabase Project
- OneSignal Account

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Asta39/scorecaddie-app.git
   cd scorecaddie-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root directory and add your Supabase and OneSignal keys:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ONESIGNAL_APP_ID=your_onesignal_app_id
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---
<div align="center">
  <i>Built with ❤️ for golfers everywhere.</i>
</div>
