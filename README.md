# Telegram Barber Booking MVP — Dart

این پروژه یک Telegram Bot واقعی و تستی برای رزرو نوبت آرایشگاه است.
هیچ UI جداگانه یا Mini App ندارد؛ رابط کاربری با پیام‌ها و Inline Keyboard خود Telegram ساخته شده است.

## امکانات

- `/start` و منوی اصلی
- انتخاب خدمت
- انتخاب تاریخ
- نمایش Slotهای زمانی
- انتخاب خودکار آرایشگر مجاز
- جلوگیری از رزرو همزمان یک آرایشگر در یک تاریخ/ساعت
- تأیید رزرو
- مشاهده رزروهای کاربر با `/bookings`
- لغو فرآیند با `/cancel`
- داده‌ها فعلاً در RAM هستند و با خاموش شدن برنامه پاک می‌شوند
- بدون Supabase و بدون دیتابیس برای تست اولیه

## 1) ساخت ربات در Telegram

داخل Telegram برو به `@BotFather` و `/newbot` را بفرست.
نام و username ربات را انتخاب کن. BotFather یک Token می‌دهد؛ Token را خصوصی نگه دار.

## 2) اجرای پروژه

در VS Code ترمینال را داخل همین پوشه باز کن:

```bash
dart pub get
dart run -DBOT_TOKEN=YOUR_BOT_TOKEN
```

مثال:

```bash
dart run -DBOT_TOKEN=123456:ABCDEF...
```

بعد داخل Telegram ربات را باز کن و `/start` بفرست.

## 3) اگر Dart نصب نیست

Flutter SDK معمولاً Dart را هم همراه خود دارد. می‌توانی در ترمینال بررسی کنی:

```bash
dart --version
flutter --version
```

برای این Bot به Flutter UI نیاز نیست؛ خود Dart برای Backend/Telegram Bot کافی است.

## 4) ساختار

```text
telegram_barber_bot_mvp/
  bin/
    bot.dart
  pubspec.yaml
  README.md
  .gitignore
```

## 5) نسخه فعلی تستی

داده‌های زیر داخل کد هستند:

- یک آرایشگاه نمونه
- 3 خدمت
- 3 آرایشگر
- ساعت‌های نمونه از 10 تا 20

هر رزرو در حافظه برنامه ذخیره می‌شود. با خاموش/ری‌استارت کردن Bot، رزروها پاک می‌شوند.

## 6) مرحله بعد برای نسخه واقعی

بعداً Supabase را اضافه کن:

- `vendors`
- `staff`
- `services`
- `staff_services`
- `bookings`
- `booking_holds`

و بهتر است منطق اصلی رزرو در Backend/Core قرار بگیرد؛ Bot فقط رابط Telegram باشد.

برای جلوگیری قطعی از Double Booking، در نسخه Production باید کنترل همزمانی در PostgreSQL/Supabase انجام شود، نه فقط داخل این کد.

## 7) Reminder

برای ارسال یادآوری مثلاً 30 دقیقه قبل از نوبت، یک Job زمان‌بندی‌شده در Backend لازم است که Telegram Bot API یعنی `sendMessage` را صدا بزند.

## امنیت

Token ربات را داخل GitHub یا فایل عمومی قرار نده. برای Production از Secret/Environment Variable استفاده کن.
