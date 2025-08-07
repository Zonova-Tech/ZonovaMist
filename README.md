# 🗺️ MapMarket - Flutter Project

MapMarket is a complete Flutter application for both **Web** and **Mobile**, featuring secure JWT authentication, modern UI, Riverpod for scalable state management, and built-in internationalization. It also comes with a **dummy Node.js backend** to handle user authentication.

---

## 🚀 Features

- ✅ **Cross-platform**: Works on Android, iOS, and Web
- 🔐 **Authentication**: JWT-based login & registration
- ⚙️ **State Management**: Powered by `Riverpod`
- 🧾 **Form Handling**: Built using `flutter_form_builder`
- 🌍 **Internationalization (i18n)**: Supports `en` and `es`
- 🎨 **Modern UI**: Professional yellow & green themed interface
- 🧪 **Testing**: Includes basic widget tests (e.g., login screen)
- 🧰 **Linting**: Enforced with `flutter_lints`
- 🖥️ **Backend**: Node.js + Express dummy server

---

## 🛠️ Prerequisites

Before running the project, ensure the following are installed:

| Tool            | Required Version                     | Guide                                                                 |
| --------------- | ------------------------------------ | --------------------------------------------------------------------- |
| **Flutter SDK** | 3.19 or above                        | [Flutter Install Guide](https://flutter.dev/docs/get-started/install) |
| **Node.js**     | 18.x or above                        | [Node.js Install Guide](https://nodejs.org/)                          |
| **Editor**      | Android Studio (with Flutter plugin) | Recommended                                                           |

---

## 📦 Project Setup

### 🔹 Step 1: Backend Setup

1. Navigate to the `backend` directory:

   ```bash
   cd backend
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Start the server:
   ```bash
   node server.js
   ```

> ✅ Server will run on `http://localhost:5000`. Keep it running while using the Flutter app.

---

### 🔹 Step 2: Flutter App Setup

> ⚠️ **Note:** The Flutter project (`map_market`) is already created.

1. Open **Android Studio**
2. Select **Open an existing project** and choose the `map_market` folder
3. Wait for Android Studio to load the project
4. Click **"Get Dependencies"** or run:
   ```bash
   flutter pub get
   ```

---

### 🔹 Step 3: Set Flutter & Dart SDK Paths

> Ensure SDK paths are correctly configured:

1. In Android Studio, go to:

   - `File > Settings > Languages & Frameworks > Flutter` (Windows/Linux)
   - `Android Studio > Preferences > Languages & Frameworks > Flutter` (macOS)

2. Set the **Flutter SDK path** (e.g., `C:\src\flutter`)

3. Dart SDK path will auto-fill.

4. Click **Apply** > **OK**

---

### 🔹 Step 4: Run the App

1. Make sure the backend is still running on `http://localhost:5000`
2. In Android Studio:
   - Select a device or **Chrome** from the device list
   - Click the **Run ▶️** button

---

## 📁 Project Structure

```
map_market/
│
├── lib/
│   ├── main.dart
│   ├── features/           # Screens & UI
│   ├── services/           # API & Auth logic
│   ├── models/             # Data models
│   ├── providers/          # Riverpod providers
│   └── l10n/               # Localization files
│
├── test/                   # Unit & widget tests
├── pubspec.yaml
└── backend/                # Node.js dummy server
```

---

## 🧪 Sample Test

Run widget tests:

```bash
flutter test
```

---

## 🧑‍💻 Author & Credits

- Created by **[ZONOVA (PVT) LTD]**

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
