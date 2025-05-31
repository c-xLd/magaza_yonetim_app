import 'package:flutter/material.dart';
import '../models/user.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final User? user;
  final List<Widget>? actions;
  final String? title;
  final bool showUserInfo;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final ScrollController? scrollController;
  final String? subtitle; // Alt başlık/konum bilgisi için
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool? centerTitle;
  final bool elevation;
  final Function()? onTitleTap; // Başlığa tıklandığında çalışacak fonksiyon

  const CustomAppBar({
    super.key,
    this.user,
    this.actions,
    this.title,
    this.showUserInfo = true,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.scrollController,
    this.subtitle,
    this.height = 80.0,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle,
    this.elevation = false,
    this.onTitleTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final isScrolled = scrollOffset > 20; // kaydırma eşiği

    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.depth == 0) {
          _onScroll();
        }
        return false;
      },
      child: AppBar(
        backgroundColor:
            widget.backgroundColor ?? colorScheme.surface,
        foregroundColor:
            widget.foregroundColor ?? colorScheme.onSurface,
        elevation: widget.elevation ? 3 : 0,
        scrolledUnderElevation: 8.0,
        centerTitle: widget.centerTitle ?? true,
        toolbarHeight: widget.height,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        leading: widget.leading,
        title: _buildAppBarContent(),
        actions: widget.actions ?? [],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        shadowColor: colorScheme.shadow.withOpacity(0.08),
      ),
    );
  }

  // AppBar içeriğini oluştur
  Widget _buildAppBarContent() {
    if (widget.showUserInfo && widget.user != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf - Kullanıcı bilgisi
          Expanded(
            child: Row(
              children: [
                // Kullanıcı avatarı
                _buildUserAvatar(),
                const SizedBox(width: 12),
                // Kullanıcı adı ve rolü
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Kullanıcı adı
                      Text(
                        widget.user?.name ?? 'Kullanıcı Adı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.foregroundColor ??
                              Theme.of(context).colorScheme.onPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Kullanıcı rolü
                      if (widget.user?.role != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.user?.role.toString() ?? 'Kullanıcı',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.foregroundColor != null
                                  ? (widget.foregroundColor as Color)
                                  : Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sağ taraf - Aksiyonlar
          if (widget.actions != null && widget.actions!.isNotEmpty)
            Row(children: widget.actions!),
        ],
      );
    } else if (widget.title != null) {
      // Başlık görünümü
      return GestureDetector(
        onTap: widget.onTitleTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ana başlık
            Text(
              widget.title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.foregroundColor ??
                    Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            // Alt başlık (varsa)
            if (widget.subtitle != null) const SizedBox(height: 2),
            if (widget.subtitle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.foregroundColor ??
                        Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Container();
  }

  // Kullanıcı avatar widget'ı
  Widget _buildUserAvatar() {
    return Hero(
      tag: 'user-avatar-${widget.user?.id ?? "guest"}',
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(24),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child:
              widget.user?.photoUrl != null && widget.user!.photoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        widget.user!.photoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
        ),
      ),
    );
  }
}
