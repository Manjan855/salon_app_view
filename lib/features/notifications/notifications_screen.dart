import 'package:flutter/material.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';



class NotificationModel {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    this.iconColor = const Color(0xFF9B6FD4),
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      title: 'Booking Confirmed! 🎉',
      message: 'Your slot at Prince Hair Salon on 28th May at 10:00 AM has been confirmed.',
      time: '2 hours ago',
      icon: Icons.calendar_today_rounded,
      iconColor: Colors.greenAccent,
    ),
    NotificationModel(
      title: 'Promo Code Applied! 🏷️',
      message: 'Get up to 50% discount on women services using code SALON50.',
      time: '1 day ago',
      icon: Icons.local_offer_outlined,
      iconColor: Colors.orangeAccent,
    ),
    NotificationModel(
      title: 'Safety Warning 🛡️',
      message: 'All stylists are fully vaccinated and sanitization protocols are maintained.',
      time: '2 days ago',
      icon: Icons.shield_outlined,
      iconColor: Colors.blueAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

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
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n.isRead = true;
                  }
                });
              },
              child: Text(
                'Mark read',
                style: TextStyle(color: kPurpleLight, fontWeight: FontWeight.w600),
              ),
            )
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: kTextMuted.withValues(alpha:0.3),
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
                    'Your transactions and updates will show up here.',
                    style: TextStyle(color: kTextMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => Container(
                height: 0.5,
                color: kPurpleLight.withOpacity(0.15),
              ),
              itemBuilder: (ctx, i) {
                final notif = _notifications[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: notif.iconColor.withOpacity(0.15),
                    child: Icon(notif.icon, color: notif.iconColor, size: 20),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.title,
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 14,
                          fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                      Text(
                        notif.time,
                        style: TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notif.message,
                      style: TextStyle(color: kTextMuted, fontSize: 13, height: 1.4),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      notif.isRead = true;
                    });
                  },
                );
              },
            ),
    );
  }
}
