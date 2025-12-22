📱 Zonova Mist Admin – Frontend Release Notes
🏷️ Version 4 (v1.0.0)

Release Date: October 2025
Platforms: Android & Web (testing phase)
Build Format: AAB (Play Console)
Backend: Node.js + Express (hosted on Render)

🚀 Overview

Zonova Mist Admin is a Flutter-based management dashboard designed for hotel partners and admins.
It allows managing hotel listings, prices, availability, and booking details with a modern, responsive UI.

⚙️ Tech Stack

Framework: Flutter (Dart)

State Management: Riverpod

Networking: Dio (for REST API calls)

UI/UX: Material Design + Flutter Slidable + Custom Components

API Base: Render-hosted Express.js backend

💡 Core Features

🏨 Manage partner hotel details (add, edit, delete)

💰 Update pricing and availability

🏷️ Filter & view hotels with status tags

📸 Upload and manage hotel images

🌐 Works across Android and Web platforms

🔁 Live API integration with backend

🧑‍💻 Setup & Run Locally
1️⃣ Clone and navigate
git clone <your-repo-link>
cd frontend

2️⃣ Install dependencies
flutter pub get

3️⃣ Set your API endpoint

In your API service file (usually api_service.dart), confirm the base URL:

const String baseUrl = "https://zonova-mist.onrender.com/";

4️⃣ Run the app
🖥️ For Web:
`flutter run -d chrome`

📱 For Android:
flutter run -d android


Ensure your backend server is running before starting the app.

🧪 Testing

Try editing a hotel record:

Navigate to Partner Hotels

Tap Edit on a hotel card

Update price or status

Press Save Changes

You should see instant updates fetched from the backend after saving.

🧾 Current Release Highlights (v1.0.0)

🧱 Fully integrated CRUD interface

🔗 Connected with Render-hosted backend API

🎨 Improved design consistency and responsiveness

🧩 Optimized hotel edit and delete workflows

⚙️ Compatible with both Android and Web builds