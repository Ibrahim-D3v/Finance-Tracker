# 🌿 FinTrack

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-000000?style=for-the-badge&logo=dart&logoColor=white)

FinTrack is a premium, beautifully designed personal finance and budget tracking application built with Flutter and Supabase. It features a highly polished Material 3 Expressive UI, real-time cloud syncing, and powerful data visualization tools to help users track their spending, analyze trends, and stay within their daily budgets.

## ✨ Key Features

* **🔒 Secure Authentication:** Email & password authentication powered by Supabase Auth with Row Level Security (RLS) ensuring absolute data privacy.
* **📊 Real-Time Dashboard:** A dynamic "Safe to Spend" hero card that calculates your remaining daily budget, accompanied by a visual progress bar and "Bento Box" category summaries.
* **⚡ Quick-Add Numpad:** A custom-built, highly responsive circular numpad sheet for frictionless transaction entry.
* **📉 Deep Insights:** Interactive Line Charts (spending trends) and Donut Charts (category breakdowns) using `fl_chart`. Data can be dynamically filtered by Week, Month, 3-Months, or Year.
* **📒 Smart Ledger:** Search, filter, and view transactions cleanly grouped by date (e.g., "TODAY", "YESTERDAY", "OCTOBER 12").
* **⚙️ Advanced Preferences:** * Fully functional Light/Dark mode toggle (Charcoal & Mint Green aesthetic).
    * Dynamic Currency Selector (USD, EUR, GBP, PKR, INR, JPY, etc.).
    * Customizable Daily Budget limits.
* **📥 CSV Data Export:** Instantly generate and share spreadsheet exports of your ledger using native device share sheets.
* **🛡️ Self-Healing Streams:** Bulletproof WebSocket implementations that automatically catch heartbeat drops and reconnect gracefully when the app resumes from the background.

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart)
* **Backend / Database:** [Supabase](https://supabase.com/) (PostgreSQL)
* **State Management:** `flutter_riverpod`
* **Charting:** `fl_chart`
* **Local Storage:** `shared_preferences`
* **Export/File Handling:** `csv`, `path_provider`, `share_plus`
* **Typography:** `google_fonts` (Plus Jakarta Sans)

## 🚀 Getting Started

Follow these steps to get a local copy up and running.

### Prerequisites
* Flutter SDK (v3.19.0 or higher recommended)
* A [Supabase](https://supabase.com/) account (Free tier is perfect)

