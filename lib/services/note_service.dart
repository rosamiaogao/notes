import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';

/// All Hive code lives here, so the screens never touch Hive directly.
class NoteService {
  static const String boxName = 'notes';

  static Box<Note> get _box => Hive.box<Note>(boxName);

  /// Call once in main() before runApp().
  static Future<void> init() async {
    await Hive.initFlutter(); // sets up the storage folder
    Hive.registerAdapter(NoteAdapter()); // must be registered before opening
    await Hive.openBox<Note>(boxName);
  }

  /// Lets the UI rebuild automatically whenever the box changes.
  static ValueListenable<Box<Note>> listenable() => _box.listenable();

  // ---------------------------------------------------------------- READ
  /// Returns notes (optionally filtered by title), pinned first,
  /// then newest first.
  static List<Note> getAll({String query = ''}) {
    final q = query.trim().toLowerCase();

    final notes = _box.values
        .where((n) => q.isEmpty || n.title.toLowerCase().contains(q))
        .toList();

    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return notes;
  }

  // -------------------------------------------------------------- CREATE
  static Future<void> add({
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      createdAt: now,
    );
    // Use the id as the key so we can find the note again easily.
    await _box.put(note.id, note);
  }

  // -------------------------------------------------------------- UPDATE
  static Future<void> update(
    Note note, {
    required String title,
    required String content,
  }) async {
    note.title = title.trim();
    note.content = content.trim();
    await note.save(); // HiveObject knows its own box + key
  }

  static Future<void> togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    await note.save();
  }

  // -------------------------------------------------------------- DELETE
  static Future<void> delete(Note note) async {
    await note.delete();
  }
}
