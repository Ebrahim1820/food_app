import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class LegalSection {
  final String title;
  final String body;
  const LegalSection({required this.title, required this.body});
}

class LegalHighlight {
  final IconData icon;
  final Color color;
  final String label;
  const LegalHighlight({
    required this.icon,
    required this.color,
    required this.label,
  });
}

// ── Main scaffold ─────────────────────────────────────────────────────────────

/// Reusable legal document viewer shared across customer and business partner
/// dashboards. Adapts between portrait (expandable accordion) and landscape
/// (fixed TOC sidebar + scrollable content pane) automatically.
class LegalDocumentScaffold extends StatefulWidget {
  const LegalDocumentScaffold({
    super.key,
    required this.title,
    required this.headerIcon,
    required this.gradientColors,
    required this.subtitle,
    required this.lastUpdated,
    required this.sections,
    this.highlights = const [],
  });

  final String title;
  final IconData headerIcon;
  final List<Color> gradientColors;
  final String subtitle;
  final String lastUpdated;
  final List<LegalSection> sections;
  final List<LegalHighlight> highlights;

  @override
  State<LegalDocumentScaffold> createState() => _LegalDocumentScaffoldState();
}

class _LegalDocumentScaffoldState extends State<LegalDocumentScaffold> {
  int _landscapeSelected = 0;
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(widget.sections.length, (i) => i == 0);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.gradientColors.first,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: isLandscape
          ? _buildLandscape(context, safe)
          : _buildPortrait(context, safe),
    );
  }

  // ── Portrait ─────────────────────────────────────────────────────────────

  Widget _buildPortrait(BuildContext context, EdgeInsets safe) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            title: widget.title,
            icon: widget.headerIcon,
            gradientColors: widget.gradientColors,
            subtitle: widget.subtitle,
            lastUpdated: widget.lastUpdated,
          ),
        ),
        if (widget.highlights.isNotEmpty)
          SliverToBoxAdapter(
            child: _HighlightsRow(highlights: widget.highlights),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, safe.bottom + 36),
          sliver: SliverList.separated(
            itemCount: widget.sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _SectionCard(
              section: widget.sections[i],
              index: i + 1,
              isExpanded: _expanded[i],
              onToggle: () => setState(() => _expanded[i] = !_expanded[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Landscape ─────────────────────────────────────────────────────────────

  Widget _buildLandscape(BuildContext context, EdgeInsets safe) {
    final section = widget.sections[_landscapeSelected];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── TOC sidebar ──────────────────────────────────────────────────────
        SizedBox(
          width: 204 + safe.left,
          child: Container(
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mini gradient mini-header
                Container(
                  padding: EdgeInsets.fromLTRB(safe.left + 14, 10, 14, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.headerIcon, color: AppColors.white, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Section list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: safe.left,
                      top: 6,
                      bottom: safe.bottom + 8,
                    ),
                    itemCount: widget.sections.length,
                    itemBuilder: (context, i) {
                      final selected = i == _landscapeSelected;
                      return InkWell(
                        onTap: () => setState(() => _landscapeSelected = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? widget.gradientColors.first.withValues(
                                    alpha: 0.08,
                                  )
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: selected
                                    ? widget.gradientColors.first
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            '${i + 1}. ${widget.sections[i].title}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? widget.gradientColors.first
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Vertical divider
        Container(width: 1, color: AppColors.border),
        // ── Content pane ─────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20 + safe.right,
              safe.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: widget.gradientColors.first,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  section.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient Hero Header ──────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.subtitle,
    required this.lastUpdated,
  });

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final String subtitle;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lastUpdated,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Highlights Row ─────────────────────────────────────────────────────────────

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({required this.highlights});
  final List<LegalHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: highlights.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final h = highlights[i];
          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: h.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: h.color.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(h.icon, color: h.color, size: 20),
                const SizedBox(height: 5),
                Text(
                  h.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: h.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Section Card (expandable) ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  final LegalSection section;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — always visible
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.gray400,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            // Body — animated in / out
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Text(
                      section.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
