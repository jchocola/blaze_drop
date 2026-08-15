# RULES.md — Полный свод правил разработки

Настоящий документ определяет строгие стандарты разработки для Flutter-приложения "PDF Editor".  
Все разработчики (включая ИИ-агентов) обязаны неукоснительно соблюдать эти правила.  
Любое отклонение должно быть согласовано с Tech Lead и зафиксировано в документации.

---

## 1. Архитектура проекта

### 1.1. Clean Architecture (трёхслойная)
Проект строго разделён на три слоя:

| Слой | Назначение | Зависимости |
|------|------------|-------------|
| **Presentation** | Виджеты, экраны, BLoC/Cubit, состояния. Содержит только UI-логику. | Зависит от Domain (через use cases). |
| **Domain** | Бизнес-сущности (entities), интерфейсы репозиториев, варианты использования (use cases). Не содержит Flutter-кода. | Независим от других слоёв. |
| **Data** | Реализации репозиториев, источники данных (локальные / удалённые), DTO-модели. | Зависит от Domain. |

### 1.2. Структура каталогов (обязательная)
ib/
├── core/ # Общие компоненты (не зависят от фич)
│ ├── constants/
│ │ └── constants.dart # Все константы приложения
│ ├── theme/
│ │ └── theme.dart # Светлая/тёмная тема, цвета
│ ├── di/
│ │ └── injection.dart # Регистрация зависимостей (get_it)
│ ├── utils/ # Хелперы, расширения, валидаторы
│ │ ├── file_utils.dart
│ │ ├── pdf_utils.dart
│ │ └── logger.dart
│ └── router/
│ └── app_router.dart # go_router конфигурация
├── features/ # Каждая фича (функциональный модуль)
│ └── pdf_editor/ # Пример фичи (PDF-редактор)
│ ├── presentation/
│ │ ├── pages/ # Экраны (виджеты верхнего уровня)
│ │ ├── widgets/ # Переиспользуемые виджеты для этой фичи
│ │ └── cubit/ # BLoC/Cubit для фичи
│ │ └── pdf_editor_cubit.dart
│ ├── domain/
│ │ ├── entities/ # Бизнес-модели (PdfDocument, PageRange и т.п.)
│ │ ├── repositories/ # Интерфейсы репозиториев
│ │ └── use_cases/ # Варианты использования (каждый в отдельном файле)
│ └── data/
│ ├── models/ # DTO для работы с данными
│ ├── datasources/ # Источники (например, локальные файлы)
│ └── repositories_impl/ # Реализации интерфейсов репозиториев
└── main.dart



**Правило:** Каждая фича должна быть независима от других (кроме core).  
Переиспользуемые компоненты выносятся в core (например, диалоги, кнопки).

---

## 2. Управление состоянием (BLoC / Cubit)

### 2.1. Общие принципы
- Используйте **Cubit** для простых состояний (один стрим событий), **Bloc** – когда нужна сложная обработка событий.
- Каждый экран (или сложная часть экрана) получает собственный Cubit/Bloc.
- Состояния должны быть **иммутабельными** – использовать `freezed` или `equatable`.
- В Cubit не должно быть бизнес-логики – только вызов use cases и преобразование результата в состояние.

### 2.2. Структура Cubit
```dart
class PdfEditorCubit extends Cubit<PdfEditorState> {
  final MergePdfUseCase mergePdfUseCase;
  final SplitPdfUseCase splitPdfUseCase;
  // ... другие зависимости

  PdfEditorCubit({
    required this.mergePdfUseCase,
    required this.splitPdfUseCase,
    // ...
  }) : super(PdfEditorInitial());

  Future<void> mergeFiles(List<File> files, List<PageRange> ranges) async {
    emit(PdfEditorLoading());
    try {
      final result = await mergePdfUseCase.execute(files, ranges);
      emit(PdfEditorSuccess(result));
    } catch (e, stack) {
      emit(PdfEditorError(e.toString()));
      // Логирование ошибки
      logError(e, stack);
    }
  }
}

###2.3. События (для Bloc)

Каждое событие – отдельный класс, описывающий намерение пользователя.
Используйте freezed для генерации sealed классов.
2.4. Подписка на состояния

Виджеты подписываются на BlocProvider / BlocBuilder / BlocListener.
Не используйте context.read в build – только для вызовов методов вне билдера.

# 3.Внедрение зависимостей (get_it)

3.1. Регистрация сервисов

Все зависимости регистрируются в core/di/injection.dart через метод setupLocator().
Используйте следующие скоупы:
registerLazySingleton – для сервисов без состояния (репозитории, use cases).
registerFactory – для Cubit/Bloc (создаются заново при каждом обращении).
registerSingleton – для синглтонов с инициализацией (например, SharedPreferences).

3.2. Пример регистрации

final sl = GetIt.instance;

void setupLocator() {
  // Внешние сервисы
  sl.registerSingletonAsync<SharedPreferences>(() => SharedPreferences.getInstance());
  sl.registerLazySingleton<FilePicker>(() => FilePicker.platform);

  // Репозитории
  sl.registerLazySingleton<PdfRepository>(
    () => PdfRepositoryImpl(sl(), sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => MergePdfUseCase(sl()));
  sl.registerLazySingleton(() => SplitPdfUseCase(sl()));
  sl.registerLazySingleton(() => RotatePdfUseCase(sl()));
  // ...

  // Cubit
  sl.registerFactory(
    () => PdfEditorCubit(
      mergePdfUseCase: sl(),
      splitPdfUseCase: sl(),
      rotatePdfUseCase: sl(),
      // ...
    ),
  );
}

3.3. Использование в виджетах

Запрещено вызывать sl.get<...>() внутри build. Вместо этого:
Для Cubit – BlocProvider.value или BlocProvider(create: (context) => sl()).
Для других зависимостей – передавайте через конструктор виджета (если это не Cubit) или используйте context.read только для вызова методов.


4. Навигация (go_router)

4.1. Конфигурация маршрутов

Все маршруты определяются в core/router/app_router.dart.
Используйте именованные пути и объекты GoRouter.
Передача аргументов – через extra или параметры пути (например, /pdf/:id).

4.2. Пример

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: RouteNames.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: RouteNames.pdfEditor,
      builder: (context, state) {
        final args = state.extra as PdfEditorArgs? ?? const PdfEditorArgs();
        return PdfEditorPage(args: args);
      },
    ),
    // Вложенные маршруты (ShellRoute) для табов
  ],
);

4.3. Навигация

Используйте context.go() или context.push() (не Navigator.push).
Для возврата – context.pop().


5. Константы (constants.dart)

Все литералы (строки, числа, размеры, длительности, ключи) выносятся в core/constants/constants.dart.
Группируйте по смыслу в отдельных классах:

class AppConstants {
  static const String appName = 'PDF Editor';
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
}

class StorageKeys {
  static const String themeMode = 'theme_mode';
  static const String recentFiles = 'recent_files';
}

class RouteNames {
  static const String home = '/';
  static const String pdfEditor = '/pdf-editor';
  static const String settings = '/settings';
}

Запрещено использовать "магические числа/строки" прямо в коде. Исключение – циклы и математические формулы, где значение очевидно.

6. Тема и цвета (theme.dart)

В core/theme/theme.dart определяются ThemeData для светлой и тёмной тем.
Все цвета вынесены в класс AppColors:
class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color error = Color(0xFFB00020);
}

Используйте Theme.of(context).colorScheme для динамических цветов.
Для текста – Theme.of(context).textTheme.
Избегайте прямых цветов в виджетах – используйте стили темы.

7. Работа с PDF-пакетами (конкретные инструкции)

Приложение использует следующие пакеты (версии строго фиксированы, см. FUNCTIONALITY.md):

7.1. Правила использования

Все операции с PDF должны выполняться в изолятах (или через compute), чтобы не блокировать UI.
Для тяжёлых операций (объединение больших файлов) используйте прогресс-коллбэки, где это возможно.
Временные файлы создаются в директории Directory.systemTemp и удаляются после завершения.

8. Обработка ошибок и логирование

8.1. Исключения

Определите иерархию кастомных исключений в доменном слое (например, PdfOperationException, FileAccessException).
Все async-операции обёрнуты в try/catch.
В Cubit перехватывайте ошибки и эмиттите состояние PdfEditorError.
8.2. Логирование

Используйте централизованный логгер (например, logger пакет) с уровнями (debug, info, warning, error).
В продакшене логи ошибок отправляются в удалённый сервис (например, Firebase Crashlytics).
8.3. Пользовательские сообщения

Ошибки должны быть переведены в понятный для пользователя текст (локализация в будущем).


9. Тестирование

9.1. Виды тестов

Unit-тесты – для use cases, репозиториев (с моками), Cubit.
Widget-тесты – для экранов и виджетов (с использованием bloc_test).
Integration-тесты – для критических путей (например, полный цикл слияния).
9.2. Инструменты

test, flutter_test, mocktail (или mockito).
Для тестирования PDF-операций используйте тестовые файлы (заранее подготовленные) в test/assets/.
9.3. Покрытие

Минимальное покрытие – 80% для бизнес-логики (домен и Cubit).

9.4. Пример теста Cubit

blocTest<PdfEditorCubit, PdfEditorState>(
  'emits [Loading, Success] when mergeFiles succeeds',
  build: () => PdfEditorCubit(
    mergePdfUseCase: MockMergePdfUseCase(),
    // ...
  ),
  act: (cubit) => cubit.mergeFiles([...]),
  expect: () => [PdfEditorLoading(), PdfEditorSuccess(result)],
);

10. Производительность и оптимизация

Избегайте лишних перестроений:
Используйте const виджеты где возможно.
Применяйте RepaintBoundary для сложных анимаций.
Для списков – ListView.builder.
Для рендеринга PDF используйте PdfViewer с кэшированием страниц (cacheExtent).
При работе с большими файлами используйте потоковую обработку (например, pdf_combiner поддерживает Stream).
Освобождайте ресурсы в dispose (отменяйте подписки, закрывайте файлы).

11. Безопасность

Не храните пароли, токены или приватные данные в коде – используйте .env и flutter_dotenv.
При запросе разрешений (чтение/запись файлов) проверяйте их наличие.
Все пользовательские файлы обрабатываются локально и не передаются на сервер без явного согласия.


12. Стиль кода и форматирование

12.1. Официальный стиль Dart

Следуйте Effective Dart.
Используйте dart format для форматирования.
Настройте IDE на автоформатирование при сохранении.
12.2. Именование

Классы – UpperCamelCase.
Переменные, методы, параметры – lowerCamelCase.
Константы – lowerCamelCase (предпочтительно) или SCREAMING_SNAKE_CASE (для ключей).
Файлы – snake_case.
Приватные члены – начинаются с _.
12.3. Импорты

Упорядочивайте по группам:
Dart SDK (dart:...)
Flutter SDK (package:flutter/...)
Внешние пакеты
Внутренние (по алфавиту)
Избегайте import 'package:...' с относительными путями внутри фичи – предпочтительно абсолютные пути.
12.4. Длина строк и методов

Максимальная длина строки – 80 символов (исключение – строки документации).
Методы не должны превышать 30 строк – разбивайте на приватные методы.
Классы – максимум 300 строк (если больше, выделяйте подклассы).
13. Документирование кода

Все публичные классы, методы и переменные должны иметь документацию в формате ///.
Документация пишется на английском языке (или русском, если команда договорится).
Пример:

/// Merges multiple PDF files into a single document.
///
/// [files] – list of input files.
/// [pageRanges] – optional page ranges for each file.
/// Returns a [File] containing the merged PDF.
Future<File> mergePdfFiles(List<File> files, List<PageRange>? pageRanges);

14. Работа с Git

Используем Git Flow:
main – стабильная версия (только релизы).
develop – основная ветка разработки.
feature/название – для каждой функциональности.
hotfix/... – для критических исправлений.
Коммиты должны быть атомарными и иметь осмысленные сообщения (императив, заголовок до 50 символов, тело при необходимости).
Пример сообщения: feat(pdf): add merge functionality with page selection
Pull Request ы должны проходить code review (минимум два аппрува).
Перед PR убедитесь, что все тесты проходят и код отформатирован.


15. Сборка и окружения

Используйте флейворы: dev, prod (переменные окружения через --dart-define).
Для iOS/Android настройте соответствующие bundle ID и иконки.
Конфигурация сборки в build.yaml (например, для генерации кода freezed).

16. Свобода выбора плагина для достижения максимального качественного UI 


17. Запрещённые практики

❌ Использование setState для сложных состояний (только для локальных UI-анимаций).
❌ Прямое обращение к GetIt.I внутри виджетов.
❌ Жёсткое кодирование цветов, размеров, строк.
❌ Игнорирование обработки ошибок.
❌ Блокирование UI длительными синхронными операциями.
❌ Использование устаревших пакетов или несоответствующих версий.

18. Ответственность ИИ-агента

ИИ-агент (вы) обязан строго следовать всем вышеуказанным правилам.
При создании нового кода сначала анализировать существующую архитектуру.
Если правило неясно – запросить уточнение у Tech Lead.
Все сгенерированные файлы должны соответствовать структуре и стилю.
Настоящий документ является обязательным для исполнения. Версия 1.0, утверждена 2026-08-06.