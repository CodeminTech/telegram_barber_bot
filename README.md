# 💈 Telegram Barber Bot

A lightweight Telegram-based barber booking system built with **Dart** and the **Telegram Bot API**, designed to simplify appointment booking directly inside Telegram.

The bot allows customers to browse available services, select a date and time, choose an available barber, confirm their appointment, and view their existing bookings — all through Telegram's inline keyboard interface.

---

## ✨ Features

### 📅 Appointment Booking

* 📅 Book barber appointments directly through Telegram
* 💇 Select available barber services
* 📆 Choose an appointment date
* 🕐 Select an available time slot
* 👤 Automatically find available barbers
* 🧾 Review booking details before confirmation
* ✅ Confirm appointments
* ⚠️ Prevent double booking for the same barber and time

### 💇 Barber Services

* ✂️ Haircut
* 🧔 Beard trim
* 💈 Haircut + Beard
* ⏱️ Service duration management
* 👤 Barber service availability

### 👥 User Sessions

* 🧠 Temporary session management
* 🔄 Track the user's current booking process
* 📌 Store selected service, date, time, and barber
* ❌ Cancel an active booking process

### 📋 My Bookings

* 📋 View personal bookings
* 👤 Display assigned barber
* 💇 Display selected service
* 📆 Display appointment date
* 🕐 Display appointment time

### 🤖 Telegram Bot

* 🤖 Telegram Bot API integration
* 💬 Telegram message handling
* 🔘 Inline keyboard navigation
* 🔄 Callback query handling
* ✏️ Dynamic message editing
* 📡 Long polling update handling
* ⚠️ Telegram API error handling

### 🎨 User Experience

* 📱 Fully Telegram-based interface
* 🔘 Interactive inline keyboards
* 🟢 Available time slots
* 🔴 Unavailable time slots
* ✅ Booking confirmation screens
* ℹ️ Built-in help section
* ❌ Booking cancellation

---

## 🛠️ Tech Stack

| Technology           | Usage                             |
| -------------------- | --------------------------------- |
| 🎯 Dart              | Programming language              |
| 🤖 Telegram Bot API  | Bot communication and messaging   |
| 🌐 HTTP              | HTTP requests to Telegram API     |
| 🔄 Long Polling      | Receiving Telegram updates        |
| 🧠 In-Memory Storage | Temporary bookings and sessions   |
| 📦 JSON              | API request and response handling |

---

## 🏗️ Architecture

The project follows a lightweight service-oriented structure suitable for a Telegram bot MVP.

```text
telegram_barber_bot/
│
├── bin/
│   └── telegram_barber_bot.dart
│
├── screenshots/
│   ├── main-menu.png
│   ├── services.png
│   └── booking.png
│
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## 🧩 Main Components

### 🤖 Telegram API

Handles communication with Telegram using the Bot API.

The bot communicates with Telegram through methods such as:

```text
getUpdates
sendMessage
editMessageText
answerCallbackQuery
```

---

### 📅 Booking System

The booking flow is handled through a sequence of user selections:

```text
🏠 Main Menu
      ↓
📅 Book Appointment
      ↓
💇 Select Service
      ↓
📆 Select Date
      ↓
🕐 Select Time
      ↓
👤 Select Barber
      ↓
🧾 Booking Summary
      ↓
✅ Confirm Booking
```

---

### 👤 Staff Management

Each barber has a list of services they can provide.

Example:

```dart
const StaffItem(
  'ali',
  'Ali',
  {'haircut', 'beard', 'combo'},
);
```

The system checks staff availability based on:

* 💇 Selected service
* 📆 Selected date
* 🕐 Selected time
* 📋 Existing bookings

---

### 🧠 Session Management

Each Telegram user has a temporary session:

```dart
class UserSession {
  String? vendorId;
  String? serviceId;
  String? date;
  String? time;
  String? staffId;
}
```

This allows the bot to maintain the user's progress throughout the booking process.

---

## 🗃️ Data Models

The project currently uses three main data structures.

### 💇 ServiceItem

Represents a barber service.

```text
ID
Name
Duration
```

### 👤 StaffItem

Represents a barber and the services they provide.

```text
ID
Name
Service IDs
```

### 📅 Booking

Represents a customer appointment.

```text
User ID
Username
Vendor ID
Service ID
Staff ID
Date
Time
```

---

## 🖼️ Screenshots

<div align="center">

<table>
<tr>
<td align="center">
<img src="screenshots/main-menu.png" width="220"/>
</td>
<td align="center">
<img src="screenshots/services.png" width="220"/>
</td>
<td align="center">
<img src="screenshots/booking.png" width="220"/>
</td>
</tr>
<tr>
<td>🏠 Main Menu</td>
<td>💇 Services</td>
<td>📅 Booking</td>
</tr>
</table>

</div>

---

## 🚀 Getting Started

### 1️⃣ Clone the repository

```bash
git clone https://github.com/CodeminTech/telegram_barber_bot.git
```

### 2️⃣ Navigate to the project

```bash
cd telegram_barber_bot
```

### 3️⃣ Install dependencies

```bash
dart pub get
```

### 4️⃣ Create a Telegram Bot

Open **BotFather** in Telegram and create a new bot.

Copy the generated Bot Token.

⚠️ Never publish your Bot Token in the repository.

### 5️⃣ Run the bot

```bash
dart run -DBOT_TOKEN="YOUR_BOT_TOKEN"
```

Example:

```bash
dart run -DBOT_TOKEN="123456789:YOUR_BOT_TOKEN"
```

---

## 🔐 Environment Configuration

The Telegram Bot Token is provided through Dart's compile-time environment variables:

```dart
const botToken = String.fromEnvironment('BOT_TOKEN');
```

The application checks whether the token is available before starting:

```text
BOT_TOKEN is missing.
```

This approach keeps the token outside the source code.

⚠️ If a real Bot Token has accidentally been committed to GitHub, revoke it and generate a new one through BotFather.

---

## 💾 Data Storage

The current version uses **in-memory storage** for bookings and user sessions.

```dart
final bookings = <Booking>[];

final sessions = <int, UserSession>{};
```

This makes the current version suitable for:

* 🧪 MVP development
* 🎯 Prototyping
* 🧑‍💻 Development
* 🎓 Demonstration

However, all booking data will be lost when the application stops or restarts.

---

## 📊 Availability System

The bot dynamically checks barber availability before displaying time slots.

```text
Selected Service
       ↓
Selected Date
       ↓
Selected Time
       ↓
Available Barbers
       ↓
🟢 Available
   or
🔴 Unavailable
```

A time slot becomes unavailable when all eligible barbers are already booked for that specific date and time.

---

## 🤖 Bot Commands

| Command     | Description                          |
| ----------- | ------------------------------------ |
| `/start`    | 🚀 Start the bot                     |
| `/menu`     | 🏠 Open the main menu                |
| `/bookings` | 📋 View personal bookings            |
| `/cancel`   | ❌ Cancel the current booking process |

---

## 🎯 Project Goals

This project was developed to demonstrate practical experience with:

* 🎯 Dart development
* 🤖 Telegram Bot API integration
* 🌐 REST API communication
* 🔄 Long polling
* 🔘 Telegram inline keyboards
* 🧠 Session management
* 📅 Appointment booking logic
* ⚠️ Availability and conflict handling
* 🧩 Building a real-world Telegram automation MVP

---

## 🔮 Future Improvements

The current MVP can be extended with additional features such as:

* 🗄️ Persistent database storage
* ☁️ Supabase integration
* 👨‍💼 Admin management panel
* 👤 Customer management
* 👨‍🔧 Barber management
* 📆 Full calendar system
* 🔔 Appointment reminders
* ❌ Appointment cancellation
* 🔄 Appointment rescheduling
* 💳 Online payment
* 📊 Booking statistics
* 🏪 Multi-barber-shop support
* 🌐 Web-based management dashboard
* ☁️ Cloud deployment

---

## 📈 Possible Production Architecture

The current in-memory implementation can later be evolved into a production-ready system:

```text
                    ┌──────────────────┐
                    │     Telegram     │
                    │      Client      │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   Dart Bot API   │
                    │     Backend      │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        👤 Customers      📅 Bookings    💇 Staff
              │              │              │
              └──────────────┼──────────────┘
                             ▼
                    ┌──────────────────┐
                    │     Database     │
                    └──────────────────┘
```

---

## 👩‍💻 Developer

**CodemonTech**

Flutter Developer | Mobile Application Developer

🔗 GitHub:
GitHub: https://github.com/CodeminTech
