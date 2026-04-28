<div align="center">

```
███████╗██╗     ██╗   ██╗██╗  ██╗
██╔════╝██║     ██║   ██║╚██╗██╔╝
█████╗  ██║     ██║   ██║ ╚███╔╝ 
██╔══╝  ██║     ██║   ██║ ██╔██╗ 
██║     ███████╗╚██████╔╝██╔╝ ██╗
╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝
```

**Smart Resource Allocation for Social Impact**

*Turning Unstructured NGO Data into Intelligent Action*

<br>

[![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)](https://github.com/urastogi2048/Flux)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini)

</div>

---

## 👥 Team Details

| Field | Details |
|---|---|
| **Team Name** | FLUX |
| **Team Leader** | Utkarsh Rastogi |
| **Problem Statement** | Smart Resource Allocation |

---

## 🧭 Problem Statement

NGOs across India collect vast amounts of field data — surveys, reports, and assessments - yet most of it is never processed or acted upon. The result is misallocated resources, unmet urgent needs, and volunteers operating without clear direction.

**FLUX is built to solve exactly this.**

---

## 💡 What is FLUX?

FLUX is an end-to-end intelligent resource allocation platform that transforms raw, unstructured NGO data into prioritized tasks and automatically routes them to the most suitable volunteer.

```
RAW DATA  -->  OCR EXTRACTION  -->  LLM ANALYSIS  -->  TASK GENERATION  -->  SMART ALLOCATION
```

---

## ⚡ Why FLUX?

| Challenge | FLUX's Solution |
|---|---|
| Unstructured NGO data piling up | OCR + LLM pipeline that processes any format |
| No prioritization of urgent needs | Urgency Detection Engine with real-time scoring |
| Wrong volunteer for the wrong task | Skill-based intelligent matching algorithm |
| System does not improve over time | Feedback loop that retrains and optimizes continuously |

### Core USPs

- **End-to-End Automation** - From upload to execution, zero manual steps
- **Hybrid AI Engine** - Rules-based urgency detection combined with LLM reasoning
- **Task Generation Engine** - Our core innovation; converts raw insights into structured tasks
- **Self-Improving Architecture** - Gets smarter with every completed task via feedback

---

## ✨ Features

| Feature | Description |
|---|---|
| 📤 Multi-Format Upload | Accepts Images, PDFs, and plain text |
| 🔍 OCR Extraction | Converts scanned documents to structured data |
| 🧠 LLM Analysis | Gemini-powered contextual understanding |
| 🚨 Urgency Detection | Flags and prioritizes critical needs automatically |
| 🛠️ Task Generation | Auto-creates actionable tasks from raw insights |
| 👥 Smart Volunteer Matching | Assigns volunteers by skills, proximity, and availability |
| 📊 Admin Dashboard | Real-time oversight, reporting, and insight visualization |
| 🗺️ Volunteer Map View | Location-aware task discovery for volunteers |
| 🔁 Feedback System | Continuous learning from task outcomes |
| ☁️ Cloud Storage | Secure, scalable storage on AWS S3 |

---

## 🔄 Process Flow

```
Step 1  ->  Admin uploads NGO data (Images / PDFs / Text)
Step 2  ->  Data stored securely in AWS S3
Step 3  ->  OCR Engine extracts raw text content
Step 4  ->  Gemini LLM analyzes content and detects urgency
Step 5  ->  Task Generation Engine creates structured tasks
Step 6  ->  Matching Algorithm assigns the best-fit volunteer
Step 7  ->  Volunteer executes task via mobile app
Step 8  ->  Feedback captured and system improves
```

---

## 🧩 System Architecture

```
                   +---------------------------+
                   |        Flutter App        |
                   |   (Admin + Volunteer UI)  |
                   +-------------+-------------+
                                 |
                   +-------------v-------------+
                   |    AWS EC2 + FastAPI       |
                   |         Backend            |
                   +--------+----------+--------+
                            |          |
              +-------------v--+  +----v--------------+
              |    AWS S3      |  |    OCR Engine      |
              |   (Storage)    |  |  (Text Extraction) |
              +----------------+  +--------+-----------+
                                           |
                          +----------------v-----------+
                          |       Gemini LLM API       |
                          |   (Analysis + Task Gen)    |
                          +----------------+-----------+
                                           |
                   +---------------------+-v-----------+
                   |    PostgreSQL + Firebase Firestore |
                   |            (Data Layer)            |
                   +------------------------------------+
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter & Dart |
| **Backend** | Python, FastAPI |
| **Cloud** | AWS EC2, AWS S3 |
| **Database** | PostgreSQL, Firebase Firestore |
| **AI / LLM** | Google Gemini API |
| **Auth & Realtime** | Firebase |
| **Maps** | OpenStreetMap |
| **State Management** | Riverpod |

---

## 📱 MVP Highlights

### Admin Interface
- Upload raw NGO data in any format
- Dashboard with AI-generated insights and reports
- Task creation and volunteer oversight

### Volunteer Interface
- Map-based task discovery
- Task acceptance and rejection with one tap
- Real-time progress tracking and feedback submission

---

## 🔮 Future Roadmap

| Phase | Milestones |
|---|---|
| **Phase 1 - Current** | Core pipeline, smart matching, Admin + Volunteer app, feedback loop |
| **Phase 2** | Resource Treasury Meter, Advanced Analytics, Gamification & Leaderboards |
| **Phase 3** | Predictive Need Analysis, Multi-NGO Collaboration, National Scale Deployment |

**Vision:** Build a fully intelligent, self-optimizing NGO ecosystem that operates with minimal human intervention and maximum social impact.

---

## 🔗 Project Links

| Resource | Link |
|---|---|
| 📂 GitHub Repository | [github.com/urastogi2048/Flux](https://github.com/urastogi2048/Flux.git) |
| 🎥 Demo Video | [Watch on YouTube](https://youtu.be/LYBet2X3w6w?si=EjYbPKIEgh1odD-F) |
| 🚀 MVP Build | [Download MVP](https://drive.google.com/file/d/1llDGJOj1y69HFSEOcjfNX3pVXknuJNTe/view) |
| 🧪 Prototype | [View Prototype](https://drive.google.com/file/d/1llDGJOj1y69HFSEOcjfNX3pVXknuJNTe/view) |

---

<div align="center">

Made with ❤️ for Social Impact - Team FLUX 

</div>