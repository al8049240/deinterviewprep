import 'package:deinterviewprep/presentation/quiz_screen/widgets/quiz_navigation_buttons_widget.dart';
import 'package:deinterviewprep/presentation/quiz_screen/widgets/quiz_option_widget.dart';
import 'package:deinterviewprep/presentation/quiz_screen/widgets/quiz_progress_bar_widget.dart';
import 'package:deinterviewprep/presentation/topics_list_screen/widgets/category_filter_widget.dart';
import 'package:deinterviewprep/presentation/topics_list_screen/widgets/topics_search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('category filter reports the selected category', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        CategoryFilterWidget(
          categories: const ['All', 'SQL', 'Cloud'],
          selected: 'All',
          onSelected: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('Cloud'));
    await tester.pump();

    expect(selected, 'Cloud');
  });

  testWidgets('topic search reports entered text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? query;
    await tester.pumpWidget(
      _app(
        TopicsSearchBarWidget(
          controller: controller,
          onChanged: (value) => query = value,
        ),
      ),
    );

    expect(find.text('Search For Skill'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'spark');

    expect(controller.text, 'spark');
    expect(query, 'spark');
  });

  testWidgets('quiz option can be selected before answering', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        QuizOptionWidget(
          index: 0,
          text: 'Option A',
          isSelected: false,
          isCorrect: false,
          isWrong: false,
          hasAnswered: false,
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.text('Option A'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('answered quiz option cannot be tapped and shows result icon', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        QuizOptionWidget(
          index: 1,
          text: 'Correct answer',
          isSelected: true,
          isCorrect: true,
          isWrong: false,
          hasAnswered: true,
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.tap(find.text('Correct answer'));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('multi-select missed answer renders a disabled indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        QuizOptionWidget(
          index: 2,
          text: 'Missed answer',
          isSelected: false,
          isCorrect: false,
          isWrong: false,
          isMissed: true,
          hasAnswered: true,
          isMultiSelect: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('navigation buttons invoke callbacks and show finish state', (
    tester,
  ) async {
    var previous = 0;
    var next = 0;
    await tester.pumpWidget(
      _app(
        QuizNavigationButtonsWidget(
          onPrevious: () => previous++,
          onNext: () => next++,
          isLastQuestion: true,
          hasAnswered: true,
        ),
      ),
    );

    expect(find.text('FINISH'), findsOneWidget);
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
    await tester.tap(find.text('PREVIOUS'));
    await tester.tap(find.text('FINISH'));
    expect(previous, 1);
    expect(next, 1);
  });

  testWidgets('progress bar reaches the requested fraction', (tester) async {
    await tester.pumpWidget(
      _app(const QuizProgressBarWidget(current: 3, total: 4)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.75, 0.001));
  });
}
