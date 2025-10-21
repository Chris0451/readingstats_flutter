enum ReadingStatus { toRead, reading, read }

ReadingStatus? parseReadingStatus(String? raw) {
  if (raw == null) return null;
  try {
    return ReadingStatus.values.firstWhere((e) => e.name == raw);
  } catch (_) {
    return null; // meglio null che un default sbagliato
  }
}

String label(ReadingStatus s) => switch (s) {
  ReadingStatus.toRead => 'Da leggere',
  ReadingStatus.reading => 'In lettura',
  ReadingStatus.read    => 'Letto',
};
String code(ReadingStatus s) => switch (s) {
  ReadingStatus.toRead => 'TO_READ',
  ReadingStatus.reading => 'READING',
  ReadingStatus.read    => 'READ',
};
ReadingStatus? fromCode(String? s) => switch (s) {
  'TO_READ' => ReadingStatus.toRead,
  'READING' => ReadingStatus.reading,
  'READ'    => ReadingStatus.read,
  _         => null,
};