# 🔢 FlappyPi

A mobile game inspired by Flappy Bird, where you fly through the digits of the number π. Built with Flutter/Dart for Android.

---

## 🎮 Game Modes

| Mode | Description |
|------|-------------|
| 🎮 **Classic** | Fly as far as possible, no time limit |
| ⏱ **Timed** | How many pipes can you clear in 60 seconds? |
| 👥 **Two Birds** | Two players, one phone — top and bottom half of the screen |

---

## ✨ Features

- **Shop** — 8 player skins and 6 pipe skins to unlock with coins earned during gameplay
- **Upgrades** — Shield, Slow Pipes, Wide Gap, Coin Magnet, x2 Coins
- **Combo System** — chain pipes without dying to build your combo, earn bonus coins
- **Particle Effects** — sparks on death, shield deflection and coin collection
- **Daily Bonus** — 25 free coins every 24 hours
- **Daily Missions** — 4 missions that reset each day with coin rewards
- **Achievements** — 8 achievements to unlock with popup notifications
- **Leaderboard** — top 5 scores, classic and timed records, game statistics
- **3 Difficulty Levels** — π/4 (easy), π (normal), π² (brutal)
- **Progress Saving** — everything saved locally via SharedPreferences

---

## 🛠 Tech Stack

- **Flutter** 3.x
- **Dart**
- **shared_preferences** — player data persistence
- All graphics drawn via Flutter Canvas API — zero external assets
- No audio dependencies (can be added via `audioplayers` or `just_audio`)

---

## 🚀 Getting Started

### Requirements
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.0+
- Android Studio or VS Code with the Flutter plugin
- Android SDK

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/flappypi.git
cd flappypi

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. Build APK
flutter build apk --release
```

The release APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
```

---

## 🏗 Project Structure

```
flappypi/
├── lib/
│   └── main.dart        # Entire game — engine, graphics, UI
├── android/             # Android configuration
├── pubspec.yaml         # Dependencies
└── README.md
```

The entire game lives in a single `main.dart` file, structured as:
- **GameEngine** — game logic, physics, collisions, save system
- **GP (GamePainter)** — renders everything via Flutter Canvas
- **SaveData** — data persistence through SharedPreferences

---

## 🎯 How It Works

The player controls a ball with the π symbol — every tap makes it jump. Pipes display consecutive digits of the number π in their gaps. Each cleared pipe pair earns a point and a chance at a coin.

Every 5 points the pipes speed up. On π² difficulty the game is relentless.

---

## 📄 License

MIT License — do whatever you want with it.

---

## 👤 Author
Idea and planning by Kubusiak
Built with the help of Claude (Anthropic) 🤖
