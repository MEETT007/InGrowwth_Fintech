String currency(num paise, {bool decimals = false}) {
  final negative = paise < 0;
  final absolute = paise.abs().round();
  final whole = (absolute ~/ 100).toString();
  var head = whole.length > 3 ? whole.substring(0, whole.length - 3) : '';
  final tail = whole.length > 3 ? whole.substring(whole.length - 3) : whole;
  final groups = <String>[];
  while (head.length > 2) {
    groups.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) groups.insert(0, head);
  final text = [...groups, tail].join(',');
  return '${negative ? '−' : ''}₹$text${decimals ? '.${(absolute % 100).toString().padLeft(2, '0')}' : ''}';
}

int? parseMoney(String text) {
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text.trim())) return null;
  final parts = text.trim().split('.');
  if (parts[0].length > 10 || int.parse(parts[0]) > 1000000000) return null;
  return int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
}
