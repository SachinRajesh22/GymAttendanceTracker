# Gym Attendance Application

This folder contains a Flutter version of the gym attendance tracker.

## Features

- Separate `Calendar` and `Dashboard` tabs
- One-month-at-a-time tracking
- Mobile-friendly one-day-per-row layout
- Present, absent, and holiday marking
- Sundays treated automatically as rest days
- Protein entry such as `120g`
- Workout dropdown for:
  - Full Body
  - Chest
  - Biceps
  - Triceps
  - Back
  - Abs
  - Leg
  - Shoulder
  - Cardio
- Dashboard totals and workout split counts
- Local persistence with `shared_preferences`

## Important note

Flutter SDK is not installed in this environment, so platform runner folders were not generated with `flutter create`.

Once Flutter is available on your machine:

1. Open this folder.
2. Run `flutter create .`
3. Run `flutter pub get`
4. Run `flutter run`

That will generate the Android and iOS runner folders around the app source that is already implemented here.
