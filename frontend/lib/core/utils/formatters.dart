import 'package:intl/intl.dart';

final _dateTime = DateFormat('dd MMM, HH:mm');

String fmtDate(DateTime? value) => value == null ? 'Pending' : _dateTime.format(value.toLocal());

String titleCase(String value) => value
    .split('_')
    .map((part) => part.isEmpty ? part : '${part[0]}${part.substring(1).toLowerCase()}')
    .join(' ');
