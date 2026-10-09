import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user?.id;
      context.read<NotificationProvider>().ensureLoaded(userId: userId);
    });
  }

  (IconData, Color) _styleFor(String type) {
    switch (type) {
      case 'booking':
      case 'appointment':
        return (Icons.calendar_today_rounded, Colors.greenAccent);
      case 'promo':
      case 'coupon':
      case 'offer':
        return (Icons.local_offer_outlined, Colors.orangeAccent);
      case 'payment':
        return (Icons.payments_outlined, Colors.lightBlueAccent);
      case 'safety':
        return (Icons.shield_outlined, Colors.blueAccent);
      default:
        return (Icons.notifications_none_rounded, const Color(0xFF9B6FD4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final signedIn = context.watch<AuthProvider>().user != null;

    return Scaffold(
      backgroundColor: kPurpleDark,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w700),
        ),
        backgroundColor: kPurpleMid,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: kWhite),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (notifications.isNotEmpty && provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: Text(
                'Mark read',
                style:
                    TextStyle(color: kPurpleLight, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: provider.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: kTextMuted.withValues(alpha: 0.3),
                          size: 72,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Notifications',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          signedIn
                              ? 'Booking updates and offers will show up here.'
                              : 'Sign in to see your notifications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kTextMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.refresh(
                    userId: context.read<AuthProvider>().user?.id,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => Container(
                      height: 0.5,
                      color: kPurpleLight.withOpacity(0.15),
                    ),
                    itemBuilder: (ctx, i) {
                      final notif = notifications[i];
                      final (icon, color) = _styleFor(notif.type);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  color: kWhite,
                                  fontSize: 14,
                                  fontWeight: notif.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notif.relativeTime,
                              style: TextStyle(color: kTextMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            notif.body,
                            style: TextStyle(
                              color: kTextMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        trailing: notif.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: kPurpleLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () => provider.markRead(notif),
                      );
                    },
                  ),
                ),
    );
  }
}
