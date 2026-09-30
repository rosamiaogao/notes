import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/note_card.dart';
import 'note_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  void _openForm([Note? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
    );
  }

  Future<void> _deleteWithConfirm(Note note) async {
    final ok = await confirmDelete(context, note.title);
    if (ok) {
      await NoteService.delete(note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes Keeper')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add note',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search (bonus feature)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // The list rebuilds automatically whenever the Hive box changes.
          Expanded(
            child: ValueListenableBuilder<Box<Note>>(
              valueListenable: NoteService.listenable(),
              builder: (context, box, _) {
                final notes = NoteService.getAll(query: _query);

                if (notes.isEmpty) {
                  return _EmptyState(isSearching: _query.trim().isNotEmpty);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];

                    // Swipe left/right to delete (asks for confirmation first).
                    return Dismissible(
                      key: ValueKey(note.id),
                      background: _swipeBackground(Alignment.centerLeft),
                      secondaryBackground:
                          _swipeBackground(Alignment.centerRight),
                      confirmDismiss: (_) => confirmDelete(context, note.title),
                      onDismissed: (_) => NoteService.delete(note),
                      child: NoteCard(
                        note: note,
                        onTap: () => _openForm(note),
                        onDelete: () => _deleteWithConfirm(note),
                        onTogglePin: () => NoteService.togglePin(note),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.note_add_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'No matching notes' : 'No notes yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isSearching
                ? 'Try a different title.'
                : 'Tap the + button to add your first note.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
