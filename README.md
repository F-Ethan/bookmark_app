Bookmark: Bible Reading Tracker for Grant Horner's System

A simple, intuitive Flutter app designed to help readers stay consistent with Professor Grant Horner's Bible-Reading System (also known as "The Ten Lists Bible Reading System"). This plan challenges you to read 10 chapters a day from 10 distinct lists, cycling through the entire Bible multiple times a year without commentary—just pure Scripture to deepen your engagement with God's Word.
Whether you're a first-time user or a veteran of the system, Bookmark makes tracking your progress effortless. Set your start date, log daily readings, and pick up right where you left off.
Features

User Setup: Enter your name, starting day, and date to personalize your journey.
Daily Tracking: Advance through the 10 lists (e.g., Gospels, Pentateuch, Psalms, etc.) with one-tap updates for your current day.
Persistent Storage: All progress saved locally using SharedPreferences—your data stays secure and accessible across sessions.
Settings Screen: Quick access to view or reset your user info and current progress.
Clean, Minimal UI: Built with Flutter for smooth performance on iOS (and Android in future updates).
Offline-First: No internet required; focus on reading, not connectivity.

The app follows the core of Horner's system: Read one chapter from each list daily, looping back to the start when a list ends. For example:

List 1: Gospels, Acts, Epistles
List 2: Pentateuch
... (up to List 10: Revelation, etc.)

(Full list details are printed on the app's onboarding screen or can be found in Horner's original PDF guide.)
Screenshots
## still to come


Getting Started
Prerequisites

Flutter SDK: Version 3.24.0 or later (stable channel). Install from flutter.dev.
Development Tools:

For iOS: Xcode 16+ (with iOS 18+ simulator/device).
For Android: Android Studio (optional for now).


Run flutter doctor to verify your setup.

Installation

Clone the repo:
textgit clone https://github.com/F-Ethan/bookmark_app.git
cd bookmark

Install dependencies:
textflutter pub get

Run the app:
textflutter run --release  # Recommended for device testing

On iOS: Ensure your device is connected and trusted.
Build for release: flutter build ios --release (or apk for Android).



For a full build:

iOS: Open ios/Runner.xcworkspace in Xcode and archive via Product > Archive.
Android: flutter build apk --release.

Usage

Launch the App: On first open, enter your name, starting day (e.g., 1), and start date.
Daily Reading:

Tap the app to view your current day's readings (e.g., "Matthew 5, Genesis 2, Psalm 3...").
Mark as complete and advance to the next day with the "+" button.


Settings:

Access via the menu (hamburger icon).
View/edit user info or reset progress if starting over.


Pro Tip: Read your 10 chapters in order, then log in the app. Aim for consistency—Horner's system is designed to immerse you in Scripture's variety!

If you miss a day, just pick up on your current day; the app doesn't enforce strict dates.
Roadmap

 Android support (full cross-platform).
 Notifications for daily reminders.
 Export progress as PDF/CSV.
 Integration with Bible APIs for audio readings.
 Widget for home screen quick-checks.

Contributions welcome—see below!
Contributing

Fork the project.
Create a feature branch (git checkout -b feature/amazing-feature).
Commit changes (git commit -m "Add amazing feature").
Push to the branch (git push origin feature/amazing-feature).
Open a Pull Request.

Please keep contributions focused on enhancing the reading experience. Tests are appreciated (run flutter test).
License
This project is licensed under the MIT License—feel free to fork, modify, and share. See LICENSE for details (create one if needed: touch LICENSE and add MIT boilerplate).
Acknowledgments

Inspired by Professor Grant Horner's Bible Reading System (free PDF guide).
Built with ❤️ using Flutter for the love of Scripture.

Questions? Open an issue or reach out on GitHub. Let's read the Bible together—one list at a time! 📖
