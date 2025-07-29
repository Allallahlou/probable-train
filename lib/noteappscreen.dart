import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Note {
  final int id;
  final String title;

  Note({required this.id, required this.title});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(id: json['id'], title: json['title']);
  }
}

class NoteAppScreen extends StatefulWidget {
  @override
  _NoteAppScreenState createState() => _NoteAppScreenState();
}

class _NoteAppScreenState extends State<NoteAppScreen> {
  List<Note> _notes = [];
  final TextEditingController _controller = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/notes'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _notes = data.map((json) => Note.fromJson(json)).toList();
      });
    } else {
      throw Exception('Erreur lors du chargement des notes');
    }
  }

  Future<void> addNoteToServer(String title) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'content': '',
        'is_favorite': false,
        'is_deleted': false,
      }),
    );

    if (response.statusCode == 200) {
      await fetchNotes();
    } else {
      throw Exception('Erreur lors de l\'ajout');
    }
  }

  void _addNote() async {
    final noteText = _controller.text.trim();
    if (noteText.isNotEmpty) {
      await addNoteToServer(noteText);
      _controller.clear();
    }
  }

  void _toggleGridView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      child: ListTile(
        title: Text(note.title),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _notes.removeWhere((n) => n.id == note.id);
              // لاحقاً: أضف حذف من السيرفر هنا
            });
          },
        ),
      ),
    );
  }

  Widget _buildNotesView() {
    if (_notes.isEmpty) {
      return Center(child: Text('Aucune note.'));
    }

    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _notes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => _buildNoteCard(_notes[index]),
      );
    } else {
      return ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) => _buildNoteCard(_notes[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Notes'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.notes),
              title: Text('Toutes les notes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Mes favoris'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Récemment supprimé'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text('Catégories'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Paramètres'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              title: Text(_isGridView ? 'Affichage liste' : 'Affichage grille'),
              onTap: () {
                _toggleGridView();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Entrez une note',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addNote,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: _buildNotesView()),
        ],
      ),
    );
  }
}
