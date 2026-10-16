import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';

Future<void> addNote(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Сохранить'));
  await tester.pumpAndSettle();
}

void main() {
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
