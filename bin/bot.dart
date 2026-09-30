import 'dart:convert';
import 'package:http/http.dart' as http;

const botToken = String.fromEnvironment('BOT_TOKEN');
String get apiBase => 'https://api.telegram.org/bot$botToken';

class ServiceItem {
  final String id;
  final String name;
  final int durationMinutes;
  const ServiceItem(this.id, this.name, this.durationMinutes);
}

class StaffItem {
  final String id;
  final String name;
  final Set<String> serviceIds;
  const StaffItem(this.id, this.name, this.serviceIds);
}

class Booking {
  final int userId;
  final String username;
  final String vendorId;
  final String serviceId;
  final String staffId;
  final String date;
  final String time;
  Booking({required this.userId, required this.username, required this.vendorId, required this.serviceId, required this.staffId, required this.date, required this.time});
}

final services = <ServiceItem>[
  const ServiceItem('haircut', '✂️ کوتاهی مو', 30),
  const ServiceItem('beard', '🧔 اصلاح صورت', 20),
  const ServiceItem('combo', '💈 کوتاهی + اصلاح', 45),
];

final staff = <StaffItem>[
  const StaffItem('ali', 'علی', {'haircut', 'beard', 'combo'}),
  const StaffItem('reza', 'رضا', {'haircut', 'beard'}),
  const StaffItem('mohammad', 'محمد', {'haircut'}),
];

final bookings = <Booking>[];
final sessions = <int, UserSession>{};

class UserSession {
  String? vendorId;
  String? serviceId;
  String? date;
  String? time;
  String? staffId;
}

Future<void> main() async {
  if (botToken.isEmpty) {
    print('BOT_TOKEN is missing.');
    print('Run: dart run -DBOT_TOKEN=YOUR_TOKEN');
    return;
  }

  print('Barber Telegram Bot started.');
  print('Press Ctrl+C to stop.');
  var offset = 0;

  while (true) {
    try {
      final updates = await telegram('getUpdates', {
        'timeout': 30,
        'offset': offset,
        'allowed_updates': jsonEncode(['message', 'callback_query']),
      });
      final list = updates['result'] as List<dynamic>? ?? [];
      for (final raw in list) {
        final update = Map<String, dynamic>.from(raw as Map);
        offset = (update['update_id'] as int) + 1;
        await handleUpdate(update);
      }
    } catch (e) {
      print('Polling error: $e');
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

Future<Map<String, dynamic>> telegram(String method, Map<String, dynamic> params) async {
  final response = await http.post(
    Uri.parse('$apiBase/$method'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(params),
  );
  if (response.statusCode != 200) {
    throw Exception('Telegram HTTP ${response.statusCode}: ${response.body}');
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  if (body['ok'] != true) throw Exception('Telegram API error: ${response.body}');
  return body;
}

Future<void> handleUpdate(Map<String, dynamic> update) async {
  if (update['callback_query'] != null) {
    await handleCallback(Map<String, dynamic>.from(update['callback_query'] as Map));
  } else if (update['message'] != null) {
    await handleMessage(Map<String, dynamic>.from(update['message'] as Map));
  }
}

Future<void> handleMessage(Map<String, dynamic> message) async {
  final chat = Map<String, dynamic>.from(message['chat'] as Map);
  final user = Map<String, dynamic>.from(message['from'] as Map);
  final chatId = chat['id'] as int;
  final userId = user['id'] as int;
  final text = (message['text'] ?? '').toString().trim();

  if (text == '/start' || text == '/menu') {
    sessions[userId] = UserSession();
    await sendMenu(chatId);
    return;
  }
  if (text == '/cancel') {
    sessions.remove(userId);
    await sendMessage(chatId, '❌ عملیات لغو شد.\n\nبرای شروع دوباره /start را بزنید.');
    return;
  }
  if (text == '/bookings') {
    await sendUserBookings(chatId, userId);
    return;
  }
  await sendMessage(chatId, 'سلام 👋\nبرای رزرو نوبت از منوی زیر استفاده کن.', keyboard: mainKeyboard());
}

Future<void> sendMenu(int chatId) async {
  await sendMessage(chatId, '💈 *سیستم رزرو آرایشگاه*\n\nیکی از گزینه‌ها را انتخاب کن:', keyboard: mainKeyboard(), parseMode: 'Markdown');
}

Map<String, dynamic> mainKeyboard() => {
  'inline_keyboard': [
    [{'text': '📅 رزرو نوبت', 'callback_data': 'book'}],
    [{'text': '📋 رزروهای من', 'callback_data': 'my_bookings'}, {'text': 'ℹ️ راهنما', 'callback_data': 'help'}],
  ],
};

Future<void> handleCallback(Map<String, dynamic> query) async {
  await telegram('answerCallbackQuery', {'callback_query_id': query['id'].toString()});
  final data = query['data'].toString();
  final message = Map<String, dynamic>.from(query['message'] as Map);
  final chat = Map<String, dynamic>.from(message['chat'] as Map);
  final user = Map<String, dynamic>.from(query['from'] as Map);
  final chatId = chat['id'] as int;
  final userId = user['id'] as int;
  final username = (user['username'] ?? user['first_name'] ?? 'کاربر').toString();
  final session = sessions.putIfAbsent(userId, UserSession.new);

  if (data == 'book') {
    session.vendorId = 'barber_1';
    session.serviceId = null;
    session.date = null;
    session.time = null;
    session.staffId = null;
    await editOrSend(message, '🏪 *آرایشگاه نمونه*\n\nخدمت موردنظر را انتخاب کن:', serviceKeyboard());
    return;
  }

  if (data.startsWith('service:')) {
    session.serviceId = data.substring(8);
    session.date = null;
    session.time = null;
    session.staffId = null;
    final service = findService(session.serviceId!);
    await editOrSend(message, '${service?.name ?? 'خدمت'} انتخاب شد.\n\n📆 روز موردنظر را انتخاب کن:', dateKeyboard());
    return;
  }

  if (data.startsWith('date:')) {
    session.date = data.substring(5);
    session.time = null;
    session.staffId = null;
    await editOrSend(message, '📆 تاریخ: ${prettyDate(session.date!)}\n\n🕐 یک زمان آزاد انتخاب کن:', timeKeyboard(session.serviceId!, session.date!));
    return;
  }

  if (data.startsWith('time:')) {
    session.time = data.substring(5);
    final service = findService(session.serviceId!);
    final availableStaff = findAvailableStaff(session.serviceId!, session.date!, session.time!);
    if (availableStaff.isEmpty) {
      await editOrSend(message, '⚠️ این ساعت دیگر ظرفیت ندارد.\nلطفاً یک زمان دیگر انتخاب کن.', timeKeyboard(session.serviceId!, session.date!));
      return;
    }
    session.staffId = availableStaff.first.id;
    await editOrSend(
      message,
      '🧾 *خلاصه رزرو*\n\n🏪 آرایشگاه: آرایشگاه نمونه\n💇 خدمت: ${service?.name ?? '-'}\n👤 آرایشگر: ${availableStaff.first.name}\n📆 تاریخ: ${prettyDate(session.date!)}\n🕐 ساعت: ${session.time}\n\nآیا رزرو را تأیید می‌کنی؟',
      confirmKeyboard(),
      parseMode: 'Markdown',
    );
    return;
  }

  if (data == 'confirm') {
    if (session.serviceId == null || session.date == null || session.time == null || session.staffId == null) {
      await sendMessage(chatId, 'اطلاعات رزرو کامل نیست. دوباره /start را بزن.');
      return;
    }
    final alreadyBooked = bookings.any((b) => b.staffId == session.staffId && b.date == session.date && b.time == session.time);
    if (alreadyBooked) {
      await sendMessage(chatId, '⚠️ متأسفانه این زمان همین الان توسط شخص دیگری رزرو شد.\nدوباره یک زمان انتخاب کن.');
      await sendMenu(chatId);
      return;
    }
    bookings.add(Booking(
      userId: userId,
      username: username,
      vendorId: session.vendorId!,
      serviceId: session.serviceId!,
      staffId: session.staffId!,
      date: session.date!,
      time: session.time!,
    ));
    final service = findService(session.serviceId!);
    final chosenStaff = staff.firstWhere((s) => s.id == session.staffId);
    await editOrSend(
      message,
      '✅ *رزرو با موفقیت ثبت شد!*\n\n💇 ${service?.name ?? '-'}\n👤 ${chosenStaff.name}\n📆 ${prettyDate(session.date!)}\n🕐 ${session.time}\n\nنسخه تستی رزرو را در حافظه برنامه نگه می‌دارد.',
      mainKeyboard(),
      parseMode: 'Markdown',
    );
    return;
  }

  if (data == 'my_bookings') {
    await sendUserBookings(chatId, userId);
    return;
  }

  if (data == 'help') {
    await editOrSend(message, 'ℹ️ *راهنمای ربات*\n\n1. رزرو نوبت را بزن.\n2. خدمت را انتخاب کن.\n3. تاریخ و ساعت را انتخاب کن.\n4. رزرو را تأیید کن.\n\nدستور /cancel برای لغو فرآیند رزرو است.', mainKeyboard(), parseMode: 'Markdown');
    return;
  }

  if (data == 'back_services') {
    await editOrSend(message, 'خدمت موردنظر را انتخاب کن:', serviceKeyboard());
  }
}

Map<String, dynamic> serviceKeyboard() => {
  'inline_keyboard': [
    for (final s in services) [{'text': '${s.name} — ${s.durationMinutes} دقیقه', 'callback_data': 'service:${s.id}'}],
  ],
};

Map<String, dynamic> dateKeyboard() {
  final now = DateTime.now();
  final d1 = dateKey(now);
  final d2 = dateKey(now.add(const Duration(days: 1)));
  final d3 = dateKey(now.add(const Duration(days: 2)));
  return {'inline_keyboard': [
    [{'text': 'امروز ${prettyDate(d1)}', 'callback_data': 'date:$d1'}],
    [{'text': 'فردا ${prettyDate(d2)}', 'callback_data': 'date:$d2'}],
    [{'text': prettyDate(d3), 'callback_data': 'date:$d3'}],
  ]};
}

Map<String, dynamic> timeKeyboard(String serviceId, String date) {
  const slots = ['10:00','10:30','11:00','11:30','12:00','12:30','16:00','16:30','17:00','17:30','18:00','18:30','19:00','19:30','20:00'];
  final rows = <List<Map<String, dynamic>>>[];
  var row = <Map<String, dynamic>>[];
  for (final time in slots) {
    final available = findAvailableStaff(serviceId, date, time).isNotEmpty;
    row.add({'text': available ? '🟢 $time' : '🔴 $time', 'callback_data': available ? 'time:$time' : 'noop'});
    if (row.length == 3) { rows.add(row); row = []; }
  }
  if (row.isNotEmpty) rows.add(row);
  rows.add([{'text': '⬅️ خدمات', 'callback_data': 'back_services'}]);
  return {'inline_keyboard': rows};
}

Map<String, dynamic> confirmKeyboard() => {'inline_keyboard': [
  [{'text': '✅ تأیید رزرو', 'callback_data': 'confirm'}],
  [{'text': '❌ لغو', 'callback_data': 'book'}],
]};

Future<void> sendUserBookings(int chatId, int userId) async {
  final mine = bookings.where((b) => b.userId == userId).toList();
  if (mine.isEmpty) {
    await sendMessage(chatId, '📋 هنوز هیچ رزروی نداری.', keyboard: mainKeyboard());
    return;
  }
  final buffer = StringBuffer('📋 *رزروهای من*\n\n');
  for (var i = 0; i < mine.length; i++) {
    final b = mine[i];
    final service = findService(b.serviceId);
    final s = staff.firstWhere((x) => x.id == b.staffId);
    buffer.writeln('${i + 1}. ${service?.name ?? '-'}');
    buffer.writeln('👤 ${s.name}');
    buffer.writeln('📆 ${prettyDate(b.date)}');
    buffer.writeln('🕐 ${b.time}\n');
  }
  await sendMessage(chatId, buffer.toString(), keyboard: mainKeyboard(), parseMode: 'Markdown');
}

List<StaffItem> findAvailableStaff(String serviceId, String date, String time) {
  return staff.where((s) {
    if (!s.serviceIds.contains(serviceId)) return false;
    return !bookings.any((b) => b.staffId == s.id && b.date == date && b.time == time);
  }).toList();
}

ServiceItem? findService(String id) {
  for (final s in services) { if (s.id == id) return s; }
  return null;
}

String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String prettyDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

Future<void> sendMessage(int chatId, String text, {Map<String, dynamic>? keyboard, String? parseMode}) async {
  final params = <String, dynamic>{'chat_id': chatId, 'text': text};
  if (keyboard != null) params['reply_markup'] = jsonEncode(keyboard);
  if (parseMode != null) params['parse_mode'] = parseMode;
  await telegram('sendMessage', params);
}

Future<void> editOrSend(Map<String, dynamic> message, String text, Map<String, dynamic> keyboard, {String? parseMode}) async {
  final chat = Map<String, dynamic>.from(message['chat'] as Map);
  final chatId = chat['id'] as int;
  final messageId = message['message_id'] as int;
  final params = <String, dynamic>{'chat_id': chatId, 'message_id': messageId, 'text': text, 'reply_markup': jsonEncode(keyboard)};
  if (parseMode != null) params['parse_mode'] = parseMode;
  try {
    await telegram('editMessageText', params);
  } catch (_) {
    await sendMessage(chatId, text, keyboard: keyboard, parseMode: parseMode);
  }
}
