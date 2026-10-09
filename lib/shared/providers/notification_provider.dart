import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repo = NotificationRepository();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _loadedForUserId;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> ensureLoaded({String? userId}) async {
    if (_loadedForUserId == userId && userId != null) return;
    await refresh(userId: userId);
  }

  Future<void> refresh({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repo.getNotifications();
      _loadedForUserId = userId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    _notifications = _notifications
        .map((e) => e.id == n.id
            ? AppNotification(
                id: e.id,
                title: e.title,
                body: e.body,
                type: e.type,
                referenceId: e.referenceId,
                isRead: true,
                createdAt: e.createdAt,
              )
            : e)
        .toList();
    notifyListeners();
    await _repo.markRead(n.id);
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    _notifications = _notifications
        .map((e) => AppNotification(
              id: e.id,
              title: e.title,
              body: e.body,
              type: e.type,
              referenceId: e.referenceId,
              isRead: true,
              createdAt: e.createdAt,
            ))
        .toList();
    notifyListeners();
    await _repo.markAllRead();
  }
}
