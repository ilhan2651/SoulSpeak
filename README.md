# 📱 SoulSpeak Mobile Application (Flutter)

**SoulSpeak** is a mobile application developed as part of an academic thesis project to assist **visually and hearing-impaired users**. It features real-time **speech-to-text (STT)** and **text-to-speech (TTS)** capabilities, enriched with **emotion detection** and a **voice-command interface** for hands-free navigation.

---

## 🎯 Key Features

### 👁️ For Visually Impaired Users

* **Voice command navigation** via `RouterVoiceCommandPage`
* **Text-to-Speech page** that speaks out text with emotional context
* **STT Command Page**: Listens and executes voice commands
* **Login & Registration** with full voice guidance

### 👂 For Hearing Impaired Users

* **STT page** to transcribe real-time speech to readable text
* **Comment and save transcripts**
* **Recorded entries list** with detailed view

---

## 🗂️ Folder Structure (Overview)

```
├── hard_hearing_impaired/
│   ├── home_page_hard_hearing_impaired.dart
│   ├── speech_to_text_page.dart
│   ├── tts_text_page.dart
│   └── saved_records_page.dart
│
├── visually_impaired/
│   ├── router_voice_command_page.dart
│   ├── stt_command_page.dart
│   ├── text_to_speech_page.dart
│   └── login/registration pages
│
├── services/
│   ├── api.dart
│   ├── auth_service.dart
│   ├── stt_service.dart
│   └── tts_service.dart
```

---

## 🔌 Backend Integration

The app connects to a custom **FastAPI** backend that supports:

* **JWT authentication**
* **Emotion-aware STT & TTS** services
* MP3 audio file streaming

> Authenticated requests use tokens stored in `SharedPreferences` and attached via headers using `dio`.

---

## 🔧 Dependencies (pubspec.yaml)

| Package              | Purpose                                |
| -------------------- | -------------------------------------- |
| `flutter_tts`        | Text-to-speech engine (local fallback) |
| `speech_to_text`     | Microphone input for voice commands    |
| `dio`                | API requests with token support        |
| `shared_preferences` | Persistent auth token & user data      |
| `just_audio`         | Playing returned MP3 audio             |
| `permission_handler` | Microphone/storage permissions         |
| `path_provider`      | File access for downloads              |
| `lottie`             | Animations for visual feedback         |
| `jwt_decode`         | Extracting info from JWT               |
| `provider`           | State management                       |
| `clipboard`          | Copy text to clipboard (STT usage)     |
| `file_selector`      | Selecting files (optional media)       |
| `video_player`       | (optional) video guides or intro       |
| `audio_session`      | Advanced audio session handling        |
| `record`             | Sound recording support (if needed)    |
| `share_plus`         | Share text or audio externally         |

---

## ▶️ Running the App

1. Ensure Flutter is installed: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Clone the repo and run:

```bash
flutter pub get
flutter run
```

3. If running on Android:

```bash
flutter run -d emulator-5554  # or your connected device
```

---

## 🤝 Accessibility-Oriented Design

* Designed for screen reader compatibility
* Minimal manual interaction
* Full voice input/output cycle for visually impaired navigation
* Emotion-based voice variation for more natural communication

---

## 📄 License

This project is for academic and assistive use. Contact for collaboration or research extensions.

---

## 👤 Author

Developed by İlhan Randa as part of a university thesis project.

![Image](https://github.com/user-attachments/assets/9266b454-a9f4-4e00-b97c-f6dc5ba47f46)

![Image](https://github.com/user-attachments/assets/30351498-7df0-49c9-ac23-115d0a2a20a9)

![Image](https://github.com/user-attachments/assets/8b8a4756-19b6-46f0-9cc0-4a823e36eefc)

![Image](https://github.com/user-attachments/assets/dde8cd8d-c00d-40d5-b2db-011cde60cfc6)

![Image](https://github.com/user-attachments/assets/aa4d5966-8ac4-4e0c-bc3c-560731acd563)

![Image](https://github.com/user-attachments/assets/5d6d1eb7-fd68-4360-92ae-4bb015dc8e60)

![Image](https://github.com/user-attachments/assets/26141343-ce31-4339-910d-dbc279029527)

![Image](https://github.com/user-attachments/assets/fadfd6e4-ebe4-4384-bfb0-a70b9262ed38)

![Image](https://github.com/user-attachments/assets/092ea89c-68f1-4985-a938-ca1d89a4e157)

![Image](https://github.com/user-attachments/assets/dd8a82b1-73c3-477c-8aed-265319cb5670)

![Image](https://github.com/user-attachments/assets/b77a8c91-44f6-44e5-a136-f1a7bdb2c79a)

![Image](https://github.com/user-attachments/assets/066227e2-51a6-414d-8036-523cf8348380)

![Image](https://github.com/user-attachments/assets/99fb5795-7b9a-4014-8a97-0c2da3addddc)

![Image](https://github.com/user-attachments/assets/8496ce72-f657-42a5-91af-0f908b24bf3a)

![Image](https://github.com/user-attachments/assets/08c66a40-2031-4dcd-a5e5-68274cb5d031)

![Image](https://github.com/user-attachments/assets/57e6203c-4dc2-4022-ab69-bc5ec278687d)
