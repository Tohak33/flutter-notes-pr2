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
  int saves = 0;
}

class _NotesPageState extends State<NotesPage> {
  static const _transition = Duration(milliseconds: 360);
  static const _listTransition = Duration(milliseconds: 420);
  static const _saveHighlight = Duration(milliseconds: 850);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _listKey = GlobalKey<SliverAnimatedListState>();
  final List<_Note> _notes = [];
  _Note? _editingNote;

  Duration _motion(Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  void _saveNote() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      _showMessage('Введите текст заметки');
      return;
    }

    final note = _editingNote;
    final index = _notes.length;
    setState(() {
      if (note == null) {
        _notes.add(_Note(text));
      } else {
        note.text = text;
        note.saves++;
      }
      _editingNote = null;
      _controller.clear();
    });
    if (note == null) {
      _listKey.currentState!.insertItem(
        index,
        duration: _motion(_listTransition),
      );
    }
    FocusScope.of(context).unfocus();
    _showMessage(note == null ? 'Заметка добавлена' : 'Изменения сохранены');
  }

  void _editNote(_Note note) {
    setState(() {
      _editingNote = note;
      _controller.text = note.text;
    });
    final duration = _motion(_transition);
    if (duration == Duration.zero) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.animateTo(0, duration: duration, curve: Curves.easeOut);
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingNote = null;
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _deleteNote(_Note note, {bool afterSwipe = false}) {
    final index = _notes.indexOf(note);
    if (index == -1) return;
    setState(() {
      _notes.removeAt(index);
      if (_editingNote == note) {
        _editingNote = null;
        _controller.clear();
      }
    });
    _listKey.currentState!.removeItem(
      index,
      (context, animation) => afterSwipe
          ? const SizedBox.shrink()
          : IgnorePointer(
              child: ExcludeSemantics(
                child: _animateCard(
                  animation,
                  offset: const Offset(-0.25, 0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _noteSurface(note, index + 1),
                  ),
                ),
              ),
            ),
      duration: afterSwipe ? Duration.zero : _motion(_listTransition),
    );
    _showMessage('Заметка удалена');
  }

  void _viewNote(_Note note) {
    FocusScope.of(context).unfocus();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: _motion(_transition),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final progress = animation.drive(CurveTween(curve: Curves.easeInOut));
        return FadeTransition(
          opacity: progress,
          child: ScaleTransition(
            scale: progress.drive(Tween(begin: 0.88, end: 1.0)),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) => SafeArea(
        child: AlertDialog(
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
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _animateCard(
    Animation<double> animation, {
    required Offset offset,
    required Widget child,
  }) {
    final progress = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return SizeTransition(
      sizeFactor: progress,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: progress,
        child: SlideTransition(
          position: progress.drive(Tween(begin: offset, end: Offset.zero)),
          child: child,
        ),
      ),
    );
  }

  Widget _noteCard(_Note note, int number) {
    final colors = Theme.of(context).colorScheme;
    final duration = _motion(_transition);
    return Dismissible(
      key: ObjectKey(note),
      movementDuration: duration,
      resizeDuration: duration == Duration.zero ? null : duration,
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
      onDismissed: (_) => _deleteNote(note, afterSwipe: true),
      child: _noteSurface(note, number),
    );
  }

  Widget _noteSurface(_Note note, int number) {
    final colors = Theme.of(context).colorScheme;
    final duration = _motion(_transition);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: note.isImportant
            ? Colors.amber.shade100
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _editingNote == note ? Colors.teal : Colors.grey.shade300,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                          AnimatedSwitcher(
                            duration: duration,
                            transitionBuilder: (child, animation) =>
                                SizeTransition(
                                  axis: Axis.horizontal,
                                  sizeFactor: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                            child: note.isImportant
                                ? Padding(
                                    key: const ValueKey(true),
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Tooltip(
                                      message: 'Важная заметка',
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(key: ValueKey(false)),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: duration,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.centerLeft,
                                children: [...previous, ?current],
                              ),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: animation.drive(
                                        Tween(
                                          begin: const Offset(0, 0.25),
                                          end: Offset.zero,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                note.text,
                                key: ValueKey(note.text),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
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
          if (note.saves > 0 && duration != Duration.zero)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(note.saves),
                  duration: _saveHighlight,
                  tween: Tween(begin: 1.0, end: 0.0),
                  builder: (context, strength, child) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: strength * 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: strength),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
    final duration = _motion(_transition);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _editingNote == null
                            ? Theme.of(context).colorScheme.surfaceContainerLow
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: duration,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [...previous, ?current],
                            ),
                            child: Text(
                              _editingNote == null
                                  ? 'Новая заметка'
                                  : 'Редактирование заметки ${_notes.indexOf(_editingNote!) + 1}',
                              key: ValueKey(_editingNote),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
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
                              AnimatedSwitcher(
                                duration: duration,
                                child: _editingNote == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: TextButton(
                                          onPressed: _cancelEditing,
                                          child: const Text('Отмена'),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: duration,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        'Список заметок (${_notes.length})',
                        key: ValueKey(_notes.length),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: duration,
                      alignment: Alignment.topCenter,
                      child: _notes.isEmpty
                          ? const SizedBox.shrink()
                          : const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Нажатие — просмотр, двойное — важная, долгое — правка. '
                                'Свайп влево — удалить, вправо — снять важность.',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverAnimatedList(
                key: _listKey,
                initialItemCount: _notes.length,
                findChildIndexCallback: (key) {
                  if (key is! ObjectKey || key.value is! _Note) return null;
                  final index = _notes.indexOf(key.value as _Note);
                  return index < 0 ? null : index;
                },
                itemBuilder: (context, index, animation) {
                  final note = _notes[index];
                  return KeyedSubtree(
                    key: ObjectKey(note),
                    child: _animateCard(
                      animation,
                      offset: const Offset(0, 0.28),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _noteCard(note, index + 1),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: duration,
                child: _notes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Пока нет заметок')),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
