enum ReadingStatus { toRead, reading, read }

ReadingStatus? parseReadingStatus(String? raw) {
  if (raw == null) return null;
  try {
    return ReadingStatus.values.firstWhere((e) => e.name == raw);
  } catch (_) {
    return null; // meglio null che un default sbagliato
  }
}