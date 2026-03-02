import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // Light background color from profile
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFE040FB,
        ), // Bright purple matching the design
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '2 thông báo chưa đọc',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // List of notifications
              _buildNotificationItem(
                icon: Icons.error_outline,
                iconColor: const Color(0xFFEF4444), // Red for warning
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Cảnh báo vượt quỹ',
                description: 'Lọ Nhu cầu thiết yếu đã vượt 95% ngân sách',
                time: '2 giờ trước',
                isUnread: true,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.notifications_none,
                iconColor: const Color(0xFF3B82F6), // Blue for reminder
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Nhắc nhở chi tiêu',
                description: 'Bạn chưa ghi chú chi tiêu hôm nay',
                time: '5 giờ trước',
                isUnread: true,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.trending_up,
                iconColor: const Color(0xFF10B981), // Green for near complete
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Mục tiêu gần hoàn thành',
                description: 'Mục tiêu Mua laptop đã đạt 85%',
                time: '1 ngày trước',
                isUnread: false,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFFA855F7), // Purple for report
                iconBgColor: const Color(0xFFFAF5FF),
                title: 'Báo cáo tháng',
                description: 'Báo cáo tháng 7 đã sẵn sàng để xem',
                time: '2 ngày trước',
                isUnread: false,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF10B981), // Green for complete
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Mục tiêu hoàn thành',
                description:
                    'Chúc mừng! Bạn đã hoàn thành mục tiêu Du lịch Đà Nẵng',
                time: '3 ngày trước',
                isUnread: false,
              ),

              const SizedBox(height: 16),

              // Mark all as read button
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Đánh dấu tất cả là đã đọc',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notification settings section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Slight slate background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFEAB308), // Yellow lightbulb
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cài đặt thông báo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nhận nhắc nhở để ghi chú chi tiêu hàng ngày và cảnh báo khi vượt ngân sách',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cài đặt',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? const Color(0xFF3B82F6)
              : Colors.transparent, // Blue border if unread
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Unread dot
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
