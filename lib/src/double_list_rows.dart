part of 'paged_datatable.dart';

/// A Row renderer that uses two lists for two directional scrolling
class _DoubleListRows<K extends Comparable<K>, T> extends StatefulWidget {
  final List<ReadOnlyTableColumn> columns;
  final ScrollController horizontalController;
  final int fixedColumnCount;
  final PagedDataTableController<K, T> controller;
  final PagedDataTableConfiguration configuration;
  final List<double> sizes;

  const _DoubleListRows({
    required this.columns,
    required this.fixedColumnCount,
    required this.horizontalController,
    required this.controller,
    required this.configuration,
    required this.sizes,
  });

  @override
  State<StatefulWidget> createState() => _DoubleListRowsState<K, T>();
}

class _DoubleListRowsState<K extends Comparable<K>, T>
    extends State<_DoubleListRows<K, T>> {
  final scrollControllerGroup = LinkedScrollControllerGroup();
  late final fixedController = scrollControllerGroup.addAndGet();
  late final normalController = scrollControllerGroup.addAndGet();

  late _TableState state;

  @override
  void initState() {
    super.initState();

    state = widget.controller._state;
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = PagedDataTableTheme.of(context);
    final controller = widget.controller;
    final state = controller._state;
    final isEmpty = controller._totalItems == 0;

    // The rows area has three non-row states. Without them the table is a
    // blank surface for the whole fetch, a blank surface for an empty result,
    // and a blank surface after a failure (the error only reached debugPrint).
    if (state == _TableState.error) {
      final error = controller._currentError ?? 'Unknown error';
      final builder = widget.configuration.errorBuilder;
      return builder != null
          ? builder(context, error, controller.refresh)
          : _TableStatusView.error(error, onRetry: controller.refresh);
    }
    if (isEmpty && state == _TableState.fetching) {
      final builder = widget.configuration.loadingBuilder;
      return builder != null ? builder(context) : const _TableStatusView.loading();
    }
    if (isEmpty) {
      final builder = widget.configuration.emptyBuilder;
      return builder != null ? builder(context) : const _TableStatusView.empty();
    }

    return DefaultTextStyle(
      style: theme.cellTextStyle,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Opacity(
          opacity: state == _TableState.idle ? 1 : 0.5,
          child: Scrollbar(
            thumbVisibility: theme.verticalScrollbarVisibility,
            controller: normalController,
            child: Row(
              children: [
                SizedBox(
                  width: widget.sizes
                      .take(widget.fixedColumnCount)
                      .fold(0.0, (a, b) => a! + b),
                  child: ListView.separated(
                    primary: false,
                    controller: fixedController,
                    itemCount: controller._totalItems,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, color: Color(0xFFD6D6D6)),
                    itemBuilder: (context, index) => _FixedPartRow<K, T>(
                      index: index,
                      fixedColumnCount: widget.fixedColumnCount,
                      sizes: widget.sizes,
                      columns: widget.columns,
                    ),
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: theme.horizontalScrollbarVisibility,
                    controller: widget.horizontalController,
                    child: ListView(
                      controller: widget.horizontalController,
                      scrollDirection: Axis.horizontal,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: widget.sizes
                                  .skip(widget.fixedColumnCount)
                                  .fold(0.0, (a, b) => a + b)),
                          child: ListView.separated(
                            controller: normalController,
                            itemCount: controller._totalItems,
                            separatorBuilder: (_, __) => const Divider(
                                height: 0, color: Color(0xFFD6D6D6)),
                            itemBuilder: (context, index) =>
                                _VariablePartRow<K, T>(
                              sizes: widget.sizes,
                              index: index,
                              fixedColumnCount: widget.fixedColumnCount,
                              columns: widget.columns,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    normalController.dispose();
    fixedController.dispose();
    super.dispose();
  }
}

/// Default loading / empty / error surface for the rows area. Text takes the
/// theme's cell style so it matches the app in light and dark mode.
class _TableStatusView extends StatelessWidget {
  final _TableStatusKind kind;
  final Object? error;
  final VoidCallback? onRetry;

  const _TableStatusView.loading()
      : kind = _TableStatusKind.loading,
        error = null,
        onRetry = null;

  const _TableStatusView.empty()
      : kind = _TableStatusKind.empty,
        error = null,
        onRetry = null;

  const _TableStatusView.error(this.error, {required this.onRetry})
      : kind = _TableStatusKind.error;

  @override
  Widget build(BuildContext context) {
    final theme = PagedDataTableTheme.of(context);
    final localizations = PagedDataTableLocalization.of(context);
    final textStyle = theme.cellTextStyle;
    final mutedStyle = textStyle.copyWith(
      color: textStyle.color?.withValues(alpha: 0.6),
    );

    final Widget body = switch (kind) {
      _TableStatusKind.loading => const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      _TableStatusKind.empty => Text(
          localizations.noItemsFoundText,
          style: mutedStyle,
          textAlign: TextAlign.center,
        ),
      _TableStatusKind.error => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$error',
              style: mutedStyle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(localizations.refreshText),
            ),
          ],
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: body,
      ),
    );
  }
}

enum _TableStatusKind { loading, empty, error }
