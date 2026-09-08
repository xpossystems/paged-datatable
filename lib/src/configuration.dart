import 'package:flutter/widgets.dart';

/// Builds the widget shown in the rows area when a fetch failed.
///
/// [error] is the object the fetcher threw; [retry] re-runs the fetch for
/// the current page.
typedef PagedDataTableErrorBuilder = Widget Function(
    BuildContext context, Object error, VoidCallback retry);

/// A set of properties used to configure a [PagedDataTable]
final class PagedDataTableConfiguration {
  /// A flag that indicates if the table should copy the list of items returned
  /// by a fetch callback.
  ///
  /// This is useful when you don't want to accidentally modify the returned list.
  final bool copyItems;

  /// Shown in the rows area while the first page (or a page after an empty
  /// result) is being fetched. Defaults to a centered progress indicator.
  final WidgetBuilder? loadingBuilder;

  /// Shown in the rows area when a fetch completed with zero items. Defaults
  /// to the localized "No items found" text.
  final WidgetBuilder? emptyBuilder;

  /// Shown in the rows area when the fetcher threw. Defaults to the error's
  /// message plus a localized refresh button that retries the fetch.
  final PagedDataTableErrorBuilder? errorBuilder;

  const PagedDataTableConfiguration({
    this.copyItems = false,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });
}
