String displayDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

DateTime monthAfter(DateTime date, int count) {
  final last = DateTime(date.year, date.month + count + 1, 0).day;
  return DateTime(
    date.year,
    date.month + count,
    date.day > last ? last : date.day,
  );
}
