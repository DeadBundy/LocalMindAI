enum IntentType { addNote, showNotes, deleteAll, help, unknown }

class IntentDetector {
  IntentType detect(String input) {
    final text = input.toLowerCase();

    if (text.startsWith('note:') ||
        text.contains('remember') ||
        text.contains('add note')) {
      return IntentType.addNote;
    } else if (text.contains('show') && text.contains('note')) {
      return IntentType.showNotes;
    } else if (text.contains('delete all') || text.contains('clear notes')) {
      return IntentType.deleteAll;
    } else if (text.contains('help') || text.contains('what can you do')) {
      return IntentType.help;
    } else {
      return IntentType.unknown;
    }
  }
}
