enum CommandType {
  addNote,
  deleteAll,
  showNotes,
  summarizeNotes,
  searchNotes,
  aiQuery,
}

class CommandParser {
  static CommandType parse(String input) {
    final lower = input.toLowerCase();

    if (lower.startsWith("add ") || lower.contains("add note")) {
      return CommandType.addNote;
    } else if (lower.contains("delete all") || lower.contains("clear all")) {
      return CommandType.deleteAll;
    } else if (lower.contains("show notes") || lower.contains("list notes")) {
      return CommandType.showNotes;
    } else if (lower.contains("summarize") || lower.contains("summary")) {
      return CommandType.summarizeNotes;
    } else if (lower.contains("search") || lower.contains("find")) {
      return CommandType.searchNotes;
    } else {
      return CommandType.aiQuery; // fallback → send to Groq
    }
  }

  /// Extracts the actual content of the note from the user's sentence.
  static String extractNoteText(String input) {
    // e.g. "add Earth's diameter as a note" → "Earth's diameter"
    final pattern = RegExp(
      r"add\s+(.*?)\s+(?:as\s+a\s+note|to\s+my\s+notes)?$",
      caseSensitive: false,
    );
    final match = pattern.firstMatch(input);
    if (match != null) {
      return match.group(1)?.trim() ?? input;
    }
    return input;
  }

  /// Extracts the topic for searches like "search notes about space"
  static String extractSearchQuery(String input) {
    final pattern = RegExp(
      r"(?:search|find)\s+(?:notes\s+)?(?:about\s+)?(.*)",
      caseSensitive: false,
    );
    final match = pattern.firstMatch(input);
    if (match != null) {
      return match.group(1)?.trim() ?? "";
    }
    return input;
  }
}
