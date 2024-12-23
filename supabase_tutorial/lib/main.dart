import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: "https://thxifcoqucvhwfhpvzky.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoeGlmY29xdWN2aHdmaHB2emt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ4ODQxODUsImV4cCI6MjA1MDQ2MDE4NX0.j-SaKFC_cgiKPCK_BWwjgHvlvorti3RcE4-z6bbRR1Q");
  if (kDebugMode) {
    print('Supabase initialized successfully!');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController textController = TextEditingController();

  void addNewNote() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: textController,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      saveNote();
                      textController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('Save'))
              ],
            ));
  }

  void saveNote() async {
    await Supabase.instance.client
        .from('notes')
        .insert({'body': textController.text});
  }

  Future<void> deleteNote(int noteId) async {
    await Supabase.instance.client.from('notes').delete().eq('id', noteId);
  }

  Future<void> updateNote({
    required int noteId,
    required String updatedBody,
  }) async {
    await Supabase.instance.client
        .from('notes')
        .update({'body': updatedBody}).eq('id', noteId);
  }

  final _notesStream =
      Supabase.instance.client.from('notes').stream(primaryKey: ['id']);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: addNewNote,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final noteText = note['body'];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                child: ListTile(
                  leading: const Icon(Icons.note, color: Colors.purple),
                  title: Text(
                    noteText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Note #${index + 1}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await deleteNote(
                          note['id']); // Pass the note ID to delete
                      setState(() {}); // Refresh the UI after deletion
                    },
                  ),
                  onTap: () {
                    textController.text =
                        noteText; // Pre-fill with the existing note text
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Note'),
                        content: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Enter updated note',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              await updateNote(
                                noteId: note['id'], // Pass the note ID
                                updatedBody:
                                    textController.text, // Get updated text
                              );
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context); // Close the dialog box
                              textController.clear(); // Clear the TextField
                              setState(() {}); // Refresh UI
                            },
                            child: const Text('Update'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog box
                              textController.clear(); // Clear the TextField
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
