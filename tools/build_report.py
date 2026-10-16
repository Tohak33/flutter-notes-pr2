from pathlib import Path
from xml.sax.saxutils import escape
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.platypus import Paragraph
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
pdfmetrics.registerFont(TTFont('Arial', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold', 'C:/Windows/Fonts/arialbd.ttf'))
pdfmetrics.registerFont(TTFont('Code', 'C:/Windows/Fonts/consola.ttf'))
W, H = A4
LEFT, RIGHT = 53, W - 53
WIDTH = RIGHT - LEFT
styles = {
    'body': ParagraphStyle('body', fontName='Arial', fontSize=11, leading=16, spaceAfter=9),
    'h1': ParagraphStyle('h1', fontName='ArialBold', fontSize=18, leading=24),
    'h2': ParagraphStyle('h2', fontName='ArialBold', fontSize=13, leading=18),
    'center': ParagraphStyle('center', fontName='Arial', fontSize=12, leading=19, alignment=TA_CENTER),
    'caption': ParagraphStyle('caption', fontName='Arial', fontSize=10, leading=14, alignment=TA_CENTER),
}
output = ROOT / 'docs/report.pdf'
c = canvas.Canvas(str(output), pagesize=A4)
c.setTitle('Практическая работа № 2. Заметки на Flutter')
c.setAuthor('Куприков Антон, П-2-24')
y = H - 53
page = 1

def p(text, style='body', x=LEFT, width=WIDTH, gap=9):
    global y
    para = Paragraph(text, styles[style])
    _, h = para.wrap(width, H)
    if y - h < 48:
        raise RuntimeError(f'Page {page} overflow: {text[:50]}')
    para.drawOn(c, x, y-h)
    y -= h + gap

def heading(text):
    p(text, 'h1', gap=19)

def sub(text):
    p(text, 'h2', gap=8)

def footer():
    c.setFont('Arial', 9)
    c.setFillColorRGB(.35,.35,.35)
    c.drawString(LEFT, 30, 'Куприков Антон • П-2-24')
    c.drawRightString(RIGHT, 30, str(page))
    c.setFillColorRGB(0,0,0)

def nextpage():
    global page,y
    footer(); c.showPage(); page += 1; y = H - 53

def images(names, captions):
    global y
    top=y
    iw=225; ih=iw*844/390
    for n, cap, x in zip(names,captions,[LEFT,RIGHT-iw]):
        c.drawImage(str(ROOT/'docs/screenshots'/n),x,top-ih,width=iw,height=ih)
        para=Paragraph(cap,styles['caption']); _,hh=para.wrap(iw,60); para.drawOn(c,x,top-ih-10-hh)
    y=top-ih-55

p('ПРАКТИЧЕСКАЯ РАБОТА № 2', 'center', gap=18)
p('Разработка приложения<br/>Заметки на Flutter', 'h1', gap=24)
p('Выполнил: Куприков Антон<br/>Группа: П-2-24<br/>Дата: 16.10.2026', gap=24)
sub('Цель работы')
p('Создать приложение на Flutter и закрепить работу со стандартными виджетами, состоянием экрана и обработчиками нажатий.')
sub('Задание')
p('Пользователь вводит текст в поле и нажимает «Сохранить». Введённый текст отображается ниже в виде списка. Для выполнения требований на оценку 5 необходимо добавить удаление и редактирование существующих заметок.')
sub('Использованные материалы')
p('Лекция «Flutter, виджеты состояний»: структура проекта, runApp и MaterialApp (слайды 2–7), StatelessWidget, StatefulWidget, build, setState и dispose (слайды 10–17).')
p('Лекция «Flutter, Scaffold, Container и другие виджеты»: Scaffold (слайды 2–3), Container (4–12), Center (13–14), отступы (17), Row и кнопки (22–24), Column (27–28).')
sub('Средства разработки')
p('Flutter 3.38.7, Dart 3.10.7. Дополнительные библиотеки для приложения не используются. Подготовлены Android-проект и веб-версия из одного исходного кода.')
nextpage()
heading('Реализация приложения')
p('Основной код находится в lib/main.dart. Функция main вызывает runApp. Корневой NotesApp наследуется от StatelessWidget и задаёт MaterialApp. Экран NotesPage использует StatefulWidget, поскольку список изменяется во время работы.')
p('В состоянии экрана хранятся список строк _notes, контроллер поля _controller и индекс _editingIndex. Значение -1 означает создание новой заметки, остальные значения указывают на редактируемую запись.')
sub('Добавление и редактирование')
p('Метод _saveNote читает текст и удаляет пробелы по краям. Пустая строка отклоняется с сообщением. В зависимости от индекса строка добавляется в список или заменяет выбранную запись:')
code = '''final String text = _controller.text.trim();
if (text.isEmpty) {
  // Показываем сообщение и завершаем метод.
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
});'''
c.setFont('Code',9.5)
for line in code.splitlines():
    c.drawString(LEFT+7,y-11,line); y-=14

y-=14
p('Метод _editNote переносит текст выбранной записи в поле и сохраняет её индекс. Страница прокручивается к форме. Нажатие «Сохранить» обновляет запись без создания копии. Кнопка «Отмена» сохраняет исходную запись.')
sub('Удаление и обновление экрана')
p('Метод _deleteNote удаляет строку через removeAt. При удалении редактируемой записи форма сбрасывается. Если удалена запись перед ней, индекс редактирования уменьшается на единицу.')
p('setState сообщает Flutter об изменении данных и вызывает перестроение интерфейса. Метод dispose освобождает контроллеры. Данные хранятся в памяти и очищаются после полного перезапуска приложения.')
nextpage()
heading('Добавление и изменение заметок')
p('Scaffold и AppBar задают основу экрана. Container оформляет форму и записи, Column располагает элементы вертикально, Row размещает текст и кнопки рядом. Для ввода используется TextField, для прокрутки — ListView.')
images(['01-added.png','02-editing.png'],['Рисунок 1. Две заметки добавлены в список. Поле ввода очищено.','Рисунок 2. Выбрана первая заметка. Её текст перенесён в поле.'])
p('В режиме редактирования заголовок формы меняется, выбранная запись выделяется рамкой, появляется кнопка «Отмена». Значки карандаша и корзины вызывают изменение и удаление соответствующей записи.')
nextpage()
heading('Сохранение изменений и удаление')
p('После сохранения изменяется текст существующей записи. Количество заметок остаётся прежним. При удалении второй записи первая остаётся в списке.')
images(['03-updated.png','04-deleted.png'],['Рисунок 3. Текст первой записи изменён. В списке по-прежнему две заметки.','Рисунок 4. Вторая запись удалена. Осталась одна заметка.'])
p('Стандартные IconButton вызывают обработчики действий. Expanded позволяет тексту переноситься в пределах строки. Прокручиваемая страница остаётся доступной на небольшом экране и при открытой клавиатуре.')
nextpage()
heading('Проверка и результат работы')
sub('Автоматическая проверка')
p('Команда flutter analyze завершилась без замечаний. Команда flutter test выполнила три теста; все тесты пройдены.')
checks = [
 ('1', 'Добавление, изменение и удаление', 'Заметка добавлена; поле очищено; текст изменён без копии; последняя запись удалена.'),
 ('2', 'Пустой текст и отмена', 'Пустая строка отклонена при добавлении и изменении; отмена сохраняет исходный текст.'),
 ('3', 'Удаление при редактировании', 'Удаление предыдущей записи учитывает сдвиг индекса; удаление редактируемой сбрасывает форму.'),
]
for num,title,desc in checks:
    p(f'<b>{num}. {title}.</b> {desc}')
sub('Проверка интерфейса')
p('В собранной веб-версии при размере экрана 390 × 844 проверены ввод двух заметок, редактирование первой и удаление второй. Фактический результат показан на рисунках 1–4. Веб-версия успешно собрана командой flutter build web.')
sub('Запуск приложения')
p('В папке проекта выполнить flutter pub get, затем flutter run. Для браузера: flutter run -d chrome. Для Android требуется подключённый телефон или эмулятор. Если компилятор Windows выдаёт ошибку из-за кириллицы в пути, проект следует разместить, например, в C:\\projects\\notes_app.')
sub('Вывод')
p('Разработано приложение «Заметки», выполняющее требования на оценку 5: добавление, отображение списка, удаление и редактирование. Состояние экрана обновляется через StatefulWidget и setState. Основу интерфейса составляют виджеты из лекций преподавателя.')
sub('Репозиторий с файлами приложения')
p('<link href="https://github.com/Tohak33/flutter-notes-pr2" color="#006666">https://github.com/Tohak33/flutter-notes-pr2</link>')
p('Исходный код, инструкция по запуску и материалы отчёта размещены в репозитории. Текстовая версия отчёта находится в docs/report.md, снимки — в docs/screenshots.')
footer(); c.save()
print(output)
