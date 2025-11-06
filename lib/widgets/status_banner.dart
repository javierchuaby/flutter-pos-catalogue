import 'package:flutter/material.dart';
import 'package:mobile_dev_challenge/models/sync_status.dart';

class StatusBanner extends StatelessWidget {
  final SyncStatus status;
  final bool isOnline;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final int productCount;

  const StatusBanner({
    super.key,
    required this.status,
    required this.isOnline,
    this.errorMessage,
    this.lastSyncTime,
    required this.productCount,
  });

  Color _getStatusColor() {
    if (!isOnline) return Color(SyncStatus.offline.colorValue);
    return Color(status.colorValue);
  }

  Color _getStatusTextColor() {
    if (!isOnline) return Color(SyncStatus.offline.textColorValue);
    return Color(status.textColorValue);
  }

  IconData _getStatusIcon() {
    if (!isOnline) return Icons.wifi_off;
    
    switch (status) {
      case SyncStatus.initial:
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.success:
        return productCount > 0 ? Icons.storage : Icons.cloud_done;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.offline:
        return Icons.wifi_off;
    }
  }

  String _getStatusMessage() {
    if (!isOnline) {
      return status.getMessage(productCount: productCount);
    }
    return status.getMessage(
      productCount: productCount,
      errorMessage: errorMessage,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(),
                size: 16,
                color: _getStatusTextColor(),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _getStatusMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getStatusTextColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (lastSyncTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last sync: ${_formatDateTime(lastSyncTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
