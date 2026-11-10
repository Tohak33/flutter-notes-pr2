import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _Note {
  _Note(this.text);

  String text;
  bool isImportant = false;
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Note> _notes = [];
  _Note? _editingNote;

  void _saveNote() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите текст заметки')));
      return;
    }

    setState(() {
      final note = _editingNote;
      if (note == null) {
        _notes.add(_Note(text));
      } else {
        note.text = text;
      }
      _editingNote = null;
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _editNote(_Note note) {
    setState(() {
      _editingNote = note;
      _controller.text = note.text;
    });
    _scrollController.jumpTo(0);
  }

  void _cancelEditing() {
    setState(() {
      _editingNote = null;
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _deleteNote(_Note note) {
    setState(() {
      _notes.remove(note);
      if (_editingNote == note) {
        _editingNote = null;
        _controller.clear();
      }
    });
  }

  void _viewNote(_Note note) {
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Просмотр заметки'),
        content: SelectableText(note.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _noteCard(_Note note, int number) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      key: ObjectKey(note),
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ObjectKey(note),
        direction: note.isImportant
            ? DismissDirection.horizontal
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.star_outline),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return true;
          }
          if (note.isImportant) {
            setState(() => note.isImportant = false);
            _showMessage('Заметка снова обычная');
          }
          return false;
        },
        onDismissed: (_) {
          _deleteNote(note);
          _showMessage('Заметка удалена');
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: note.isImportant
                ? Colors.amber.shade100
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _editingNote == note ? Colors.teal : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _viewNote(note),
                  onDoubleTap: () => setState(() => note.isImportant = true),
                  onLongPress: () => _editNote(note),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        if (note.isImportant)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Tooltip(
                              message: 'Важная заметка',
                              child: Icon(
                                Icons.star,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Редактировать заметку $number',
                onPressed: () => _editNote(note),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Удалить заметку $number',
                onPressed: () => _deleteNote(note),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingNote == null
                        ? 'Новая заметка'
                        : 'Редактирование заметки ${_notes.indexOf(_editingNote!) + 1}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Текст заметки',
                      hintText: 'Что нужно записать?',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _saveNote,
                        child: const Text('Сохранить'),
                      ),
                      if (_editingNote != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelEditing,
                          child: const Text('Отмена'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Список заметок (${_notes.length})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'Нажатие — просмотр, двойное — важная, долгое — правка. '
                'Свайп влево — удалить, вправо — снять важность.',
              ),
            ],
            const SizedBox(height: 12),
            if (_notes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Пока нет заметок')),
              ),
            for (int i = 0; i < _notes.length; i++) _noteCard(_notes[i], i + 1),
          ],
        ),
      ),
    );
  }
}
