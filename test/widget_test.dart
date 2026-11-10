import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';

Future<void> addNote(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Сохранить'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Одиночное нажатие открывает полный текст заметки', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    const note =
        'Первая строка\nВторая строка\nТретья строка\nПоследняя строка';
    await addNote(tester, note);

    await tester.tap(find.text(note));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('Просмотр заметки'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      note,
    );

    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Двойное нажатие ставит звезду, свайп вправо убирает её', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await addNote(tester, 'Сдать работу');
    final note = find.text('Сдать работу');

    await tester.tap(note);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(note);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.drag(note, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsNothing);
    expect(note, findsOneWidget);
    expect(find.text('Заметка снова обычная'), findsOneWidget);

    await tester.drag(note, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(note, findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('Удержание правит выбранную запись, свайп влево удаляет её', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await addNote(tester, 'Одинаковый текст');
    await addNote(tester, 'Одинаковый текст');

    await tester.longPress(find.text('Одинаковый текст').last);
    await tester.pumpAndSettle();
    expect(find.text('Редактирование заметки 2'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await addNote(tester, 'Изменённая заметка');
    expect(find.text('Изменённая заметка'), findsOneWidget);

    final card = find.ancestor(
      of: find.text('Изменённая заметка'),
      matching: find.byType(Dismissible),
    );
    final rect = tester.getRect(card);
    await tester.dragFrom(
      Offset(rect.right - 110, rect.center.dy),
      const Offset(-490, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Изменённая заметка'), findsNothing);
    expect(find.text('Одинаковый текст'), findsOneWidget);
    expect(find.text('Заметка удалена'), findsOneWidget);
  });

  testWidgets('Добавление, изменение и удаление заметки', (tester) async {
    await tester.pumpWidget(const NotesApp());
    expect(find.text('Пока нет заметок'), findsOneWidget);
    await addNote(tester, 'Подготовиться к практике');
    expect(find.text('Подготовиться к практике'), findsOneWidget);
    expect(find.text('Список заметок (1)'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    await tester.tap(find.byTooltip('Редактировать заметку 1'));
    await tester.pumpAndSettle();
    await addNote(tester, 'Подготовить отчёт');
    expect(find.text('Подготовиться к практике'), findsNothing);
    expect(find.text('Подготовить отчёт'), findsOneWidget);
    expect(find.text('Список заметок (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Удалить заметку 1'));
    await tester.pumpAndSettle();
    expect(find.text('Пока нет заметок'), findsOneWidget);
  });

  testWidgets('Пустой текст не добавляется и не заменяет заметку', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await addNote(tester, '   ');
    expect(find.text('Список заметок (0)'), findsOneWidget);
    expect(find.text('Введите текст заметки'), findsOneWidget);
    await addNote(tester, 'Исходный текст');
    await tester.tap(find.byTooltip('Редактировать заметку 1'));
    await tester.pumpAndSettle();
    await addNote(tester, '  ');
    expect(find.text('Исходный текст'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Новая заметка'), findsOneWidget);
    expect(find.text('Исходный текст'), findsOneWidget);
  });

  testWidgets('Индекс редактирования учитывает удаление предыдущей записи', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await addNote(tester, 'Первая');
    await addNote(tester, 'Вторая');
    await tester.tap(find.byTooltip('Редактировать заметку 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить заметку 1'));
    await tester.pumpAndSettle();
    await addNote(tester, 'Вторая исправлена');
    expect(find.text('Вторая исправлена'), findsOneWidget);
    expect(find.text('Список заметок (1)'), findsOneWidget);
    await tester.tap(find.byTooltip('Редактировать заметку 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить заметку 1'));
    await tester.pumpAndSettle();
    expect(find.text('Новая заметка'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });
}
