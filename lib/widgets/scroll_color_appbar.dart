import 'package:flutter/material.dart';

/// Appbar that changes color based on scroll position
/// White background with black text when at the top
/// Black background with white text when scrolled down
class ScrollColorAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double scrollThreshold;

  const ScrollColorAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.scrollThreshold = 50.0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ScrollColorAppBar> createState() => _ScrollColorAppBarState();
}

class _ScrollColorAppBarState extends State<ScrollColorAppBar> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > widget.scrollThreshold && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= widget.scrollThreshold &&
        _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification) {
          _onScroll();
        }
        return false;
      },
      child: AppBar(
        title: Text(widget.title, style: textTheme.titleLarge),
        leading: widget.leading,
        actions: widget.actions,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        backgroundColor: _isScrolled ? colorScheme.surface : colorScheme.surfaceContainerHigh,
        foregroundColor: _isScrolled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        elevation: _isScrolled ? 3 : 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: _isScrolled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        shadowColor: colorScheme.shadow.withOpacity(0.08),
      ),
    );
  }

  // Allow external scroll controllers to be used with this AppBar
  ScrollController get scrollController => _scrollController;
}

/// Extension to easily convert a Scaffold to a Scaffold with ScrollColorAppBar
extension ScrollColorAppBarScaffold on Scaffold {
  Scaffold withScrollColorAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    double scrollThreshold = 50.0,
  }) {
    return Scaffold(
      appBar: ScrollColorAppBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        scrollThreshold: scrollThreshold,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
    );
  }
}
