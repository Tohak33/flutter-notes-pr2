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

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _notes = [];
  // -1 означает, что сейчас создаётся новая заметка.
  int _editingIndex = -1;

  // Одна кнопка добавляет новую заметку или сохраняет изменения.
  void _saveNote() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите текст заметки')));
      return;
    }

    setState(() {
      if (_editingIndex == -1) {
        _notes.add(text);
      } else {
        _notes[_editingIndex] = text;
      }
      _editingIndex = -1;
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  // Переносим текст выбранной заметки в поле ввода.
  void _editNote(int index) {
    setState(() {
      _editingIndex = index;
      _controller.text = _notes[index];
    });
    _scrollController.jumpTo(0);
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = -1;
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = -1;
        _controller.clear();
      } else if (_editingIndex > index) {
        // После удаления предыдущей записи индексы сдвигаются.
        _editingIndex--;
      }
    });
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
                    _editingIndex == -1
                        ? 'Новая заметка'
                        : 'Редактирование заметки ${_editingIndex + 1}',
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
                      if (_editingIndex != -1) ...[
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
            const SizedBox(height: 12),
            if (_notes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Пока нет заметок')),
              ),
            for (int i = 0; i < _notes.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _editingIndex == i
                        ? Colors.teal
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(_notes[i])),
                    IconButton(
                      tooltip: 'Редактировать заметку ${i + 1}',
                      onPressed: () => _editNote(i),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Удалить заметку ${i + 1}',
                      onPressed: () => _deleteNote(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
