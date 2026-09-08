import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paged_datatable/paged_datatable.dart';

/// The rows area used to be a blank surface while fetching, when the fetch
/// returned nothing, and when the fetcher threw (the error only went to
/// debugPrint). These pin the three default surfaces and the retry path.
void main() {
  Widget host(Widget table) => MaterialApp(
        localizationsDelegates: const [
          PagedDataTableLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: SizedBox(width: 800, height: 400, child: table)),
      );

  List<ReadOnlyTableColumn<String, String>> columns() => [
        TableColumn<String, String>(
          title: const Text('Name'),
          cellBuilder: (context, item, index) => Text(item),
          size: const FixedColumnSize(200),
        ),
      ];

  testWidgets('shows a progress indicator until the first page arrives',
      (tester) async {
    final gate = Completer<(List<String>, String?)>();
    await tester.pumpWidget(host(PagedDataTable<String, String>(
      columns: columns(),
      fetcher: (pageSize, sort, filter, token) => gate.future,
    )));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No items found'), findsNothing);

    gate.complete((['alpha', 'beta'], null));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('shows the localized empty text for a zero-row page',
      (tester) async {
    await tester.pumpWidget(host(PagedDataTable<String, String>(
      columns: columns(),
      fetcher: (pageSize, sort, filter, token) async => (<String>[], null),
    )));
    await tester.pumpAndSettle();

    expect(find.text('No items found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the error and Refresh retries the fetch', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(PagedDataTable<String, String>(
      columns: columns(),
      fetcher: (pageSize, sort, filter, token) async {
        calls++;
        if (calls == 1) throw StateError('items endpoint returned 502');
        return (['recovered'], null);
      },
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('items endpoint returned 502'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('recovered'), findsOneWidget);
    expect(find.text('Refresh'), findsNothing);
  });

  testWidgets('custom emptyBuilder replaces the default text', (tester) async {
    await tester.pumpWidget(host(PagedDataTable<String, String>(
      columns: columns(),
      configuration: PagedDataTableConfiguration(
        emptyBuilder: (context) => const Text('Nothing matches these filters'),
      ),
      fetcher: (pageSize, sort, filter, token) async => (<String>[], null),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Nothing matches these filters'), findsOneWidget);
    expect(find.text('No items found'), findsNothing);
  });
}
