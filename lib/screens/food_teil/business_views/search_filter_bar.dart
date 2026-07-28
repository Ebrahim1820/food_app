// lib/widgets/common/search_filter_bar.dart
//
// Drop-in search + filter chip bar reusable across any list screen.
// The caller owns all state; this widget is purely presentational.

import 'package:flutter/material.dart';

// ── Data model ───────────────────────────────────────────────────────────────

/// Describes a single [FilterChip] rendered inside [SearchFilterBar].
///
/// Build one per chip, pass them in groups via [SearchFilterBar.filterGroups].
class FilterChipOption {
  const FilterChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Text shown on the chip.
  final String label;

  /// Whether the chip appears selected / highlighted.
  final bool selected;

  /// Invoked when the user taps the chip (selection toggle).
  final VoidCallback onTap;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// A reusable search field + horizontally scrollable filter chip bar.
///
/// Combines a [TextField] for text search with one or more groups of
/// [FilterChip]s. Groups are visually separated by a thin vertical divider.
///
/// **State is owned entirely by the caller.**
/// Build [FilterChipOption] lists from your controller's reactive values and
/// wrap the widget in [Obx] so it rebuilds when state changes. Pass a
/// [TextEditingController] to let Flutter preserve focus across rebuilds, and
/// pass [activeSearchQuery] (the current `.value` of your Rx string) so the
/// clear (✕) button appears only when there is text.
///
/// ---
/// Minimal usage example:
/// ```dart
/// Obx(() => SearchFilterBar(
///   searchController: _searchCtrl,
///   onSearch:         (v) => ctrl.query.value = v,
///   searchHint:       'Search by name…',
///   activeSearchQuery: ctrl.query.value,
///   filterGroups: [
///     // Group 1 — sort
///     [
///       FilterChipOption(
///         label: 'Newest',
///         selected: ctrl.sort.value == MySort.newest,
///         onTap: () => ctrl.sort.value = MySort.newest,
///       ),
///       FilterChipOption(
///         label: 'Oldest',
///         selected: ctrl.sort.value == MySort.oldest,
///         onTap: () => ctrl.sort.value = MySort.oldest,
///       ),
///     ],
///     // Group 2 — date (separated by a divider from group 1)
///     [
///       FilterChipOption(label: 'All',   selected: …, onTap: …),
///       FilterChipOption(label: 'Today', selected: …, onTap: …),
///     ],
///   ],
/// ))
/// ```
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    this.searchController,
    this.onSearch,
    this.searchHint = 'Search…',
    this.activeSearchQuery = '',
    this.filterGroups = const [],
  });

  /// Manages the text in the search field.
  /// When `null` the search field is hidden entirely.
  final TextEditingController? searchController;

  /// Called with the latest query string on every keystroke.
  final ValueChanged<String>? onSearch;

  /// Placeholder shown when the search field is empty.
  final String searchHint;

  /// Current query string — used only to decide whether to show the ✕ button.
  /// Keep this in sync with your controller's reactive search string.
  final String activeSearchQuery;

  /// Groups of chips to render.
  /// Each inner list becomes a visual group separated from the next by a divider.
  /// An empty outer list hides the chip row completely.
  final List<List<FilterChipOption>> filterGroups;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchController != null;
    final hasChips =
        filterGroups.isNotEmpty && filterGroups.any((g) => g.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasSearch) _buildSearchField(),
        if (hasChips) _buildChipRow(context),
      ],
    );
  }

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: searchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          // Clear button appears only when there is text.
          suffixIcon: activeSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear search',
                  onPressed: () {
                    searchController!.clear();
                    onSearch?.call('');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────

  Widget _buildChipRow(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;

    // Build a flat list of widgets interleaving chips and dividers.
    final items = <Widget>[];

    for (int g = 0; g < filterGroups.length; g++) {
      final group = filterGroups[g];
      if (group.isEmpty) continue;

      // Divider between groups (skip before the first group).
      if (items.isNotEmpty) {
        items
          ..add(const SizedBox(width: 10))
          ..add(Container(width: 1, height: 22, color: dividerColor))
          ..add(const SizedBox(width: 10));
      }

      // Chips within a group.
      for (int i = 0; i < group.length; i++) {
        if (i > 0) items.add(const SizedBox(width: 6));
        final opt = group[i];
        items.add(
          FilterChip(
            label: Text(opt.label),
            selected: opt.selected,
            onSelected: (_) => opt.onTap(),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: items),
      ),
    );
  }
}
