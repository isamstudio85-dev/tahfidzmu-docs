import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/app_notification.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notificationList;
    final hasUnread = notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Pemberitahuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                await provider.markAllNotificationsAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi ditandai telah dibaca'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text(
                'Tandai Semua Dibaca',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationCard(context, provider, notif);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppTheme.primaryGreen.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Pemberitahuan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi setoran & kehadiran Anda akan muncul di sini.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppProvider provider, AppNotification notif) {
    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    switch (notif.type) {
      case 'setoran':
        iconBgColor = Colors.green.shade50;
        iconColor = Colors.green.shade800;
        iconData = Icons.menu_book_rounded;
        break;
      case 'presensi':
        iconBgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade800;
        iconData = Icons.assignment_turned_in_rounded;
        break;
      case 'peringatan':
        iconBgColor = Colors.red.shade50;
        iconColor = Colors.red.shade800;
        iconData = Icons.warning_amber_rounded;
        break;
      default:
        iconBgColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade700;
        iconData = Icons.notifications_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notif.isRead ? Colors.grey.shade200 : AppTheme.primaryGreen.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      color: notif.isRead ? Colors.white : AppTheme.primaryGreen.withValues(alpha: 0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!notif.isRead) {
            await provider.markNotificationAsRead(notif.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.poppins(
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 13.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notif.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Unread Dot Indicator
              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
