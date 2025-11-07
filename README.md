# 🧠 LocalMind AI  
> *A privacy-first intelligent notes assistant that lets you chat, reason, and organize your thoughts — securely.*

---

## 🌍 Overview  
**LocalMind AI** is a **privacy-focused intelligent assistant** built with **Flutter** and **Groq AI** that allows users to **create, manage, and analyze notes** — securely, locally, and intelligently.  

It combines:
- 💬 Natural conversation-style input  
- 🔒 AES encryption  
- 🧠 Groq-powered reasoning  
into one smooth, **on-device intelligent memory system.**

---

## 🎯 Core Idea  
> Empower users to *own* their data — not surrender it to the cloud.  
LocalMind lets your AI **see only what’s relevant**, while everything you save stays **encrypted and local**.

---

## ✨ Key Features  

| Category | Description |
|-----------|-------------|
| 📝 **Smart Notes** | Create, delete, search, and summarize notes using natural language. |
| 🤖 **AI Context Understanding** | Ask your assistant to “summarize,” “find,” or “analyze” your notes. |
| 🔐 **Privacy-First** | Every note is AES-encrypted and stored locally — even the AI can’t access raw text. |
| 🧠 **Groq-Powered Intelligence** | Integrates Groq’s *Llama 3.3 70B Versatile* model for fast, low-latency reasoning. |
| 🗣️ **Compound Intents** | Handles commands like “What’s Earth’s diameter and add that as a note.” |
| 💾 **Session Memory** | Remembers the last AI response — so “add those” or “summarize them” works! |
| 🎨 **Siri-style Assistant UI** | Dedicated chat screen with gradient design and friendly tone. |
| 🌈 **Privacy Mode** | Instantly hides your decrypted notes. |
| ⚡ **Latency Display** | Shows AI response time for transparency. |

---

## 🧰 Tech Stack  

| Layer | Technology |
|--------|-------------|
| Framework | Flutter |
| Backend AI | Groq API (Llama 3.3 – 70B Versatile) |
| Data Storage | SQLite (`sqflite`) |
| Security | AES Encryption (`encrypt`, `flutter_secure_storage`) |
| Config | `flutter_dotenv` for environment variables |
| NLP Logic | Custom `CommandParser` for rule-based intent detection |
| Design | Material 3 + Custom Gradient UI |

---

## 🔐 Privacy Promise  

LocalMind is built around **data sovereignty** — your notes belong only to you.  

They are:  
- 🔒 **Encrypted locally** using AES before saving  
- 🧠 **Decrypted only in memory** when being viewed  
- ☁️ **Never uploaded** or shared with any external service  
- 🔍 **Used selectively** by the AI (only when context is required)  

> 🧠 *You control your digital memory — not the cloud.*

---

## ⚙️ Setup Instructions  

### 1️⃣ Clone the Repository  
git clone https://github.com/DeadBundy/LocalMindAI.git
cd LocalMindAI

### 2️⃣ Install Dependencies
flutter pub get

### 3️⃣ Add Your API Key Securely
Create a .env file in your project root:
GROQ_API_KEY=your_real_groq_key_here

Ensure .gitignore contains:
.env

### 4️⃣ Run the App
flutter run

---

## 🧾 Encryption Proof  

To visually verify how **LocalMind AI** secures user data, here’s how the same note appears in the app vs. inside the local database:

| App View (Decrypted) | Database View (Encrypted) |
|:---------------------:|:-------------------------:|
| ![Decrypted Notes](images/decrypted(same_data).PNG) | ![Encrypted DB](images/encrypted(same_data).PNG) |

🧠 Even if someone opens your local SQLite database, all note text is stored as unreadable AES-encrypted strings — protecting your private data completely.

---


Built with 💙 using Flutter, Groq, and a passion for ethical AI innovation.
