# 🏋️ Gym Attendance Tracker App

A lightweight Flutter-based application to track daily gym attendance and fitness metrics with a clean and simple interface.

---

## 📱 Features

* 📅 Calendar-based attendance tracking
* 📊 Dashboard with fitness metrics
* 💾 Local data storage using SharedPreferences
* 🎯 Minimal and user-friendly UI
* ⚡ Fast and lightweight performance

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Storage:** SharedPreferences (local storage)
* **Architecture:** MVC-style structure

---

## 📂 Project Structure (Simplified)

```
lib/
│
├── main.dart
├── src/
│   ├── app.dart
│   │
│   ├── constants/
│   │   └── tracker_constants.dart
│   │
│   ├── controller/
│   │   └── tracker_controller.dart
│   │
│   ├── models/
│   │   ├── day_entry.dart
│   │   └── metrics.dart
│   │
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   └── calendar_screen.dart
│   │
│   ├── services/
│   │   └── storage_service.dart
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   └── widgets/
│       ├── metric_card.dart
│       ├── day_row_card.dart
│       └── detail_card.dart
```

---

## 🚀 Getting Started

### 1. Clone the repository

```
git clone <your-repo-link>
cd gym_attendance_application
```

### 2. Install dependencies

```
flutter pub get
```

### 3. Run the app

```
flutter run
```

---

## 📦 Build APK

To generate a release APK:

```
flutter build apk
```

Output will be in:

```
build/app/outputs/flutter-apk/
```

Choose based on your device:

* `app-arm64-v8a-release.apk` → Most modern Android phones ✅
* `app-armeabi-v7a-release.apk` → Older devices

---

## 💡 How It Works

* Users mark attendance daily
* Data is stored locally on the device
* Dashboard shows overall progress and stats
* Calendar view allows easy navigation between days

---

## 🔮 Future Improvements

* 🔐 User authentication
* ☁️ Cloud sync (Firebase/MongoDB)
* 📈 Advanced analytics and graphs
* 🎯 Workout tracking integration

---

## 👨‍💻 Author

**Sachin Rajesh**
BTech CSE Student | Model Engineering College

---

## 📄 License

This project is for educational purposes.
