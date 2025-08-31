import 'package:flutter/material.dart';
import '../models/employee_status.dart';

class StatusDisplay extends StatelessWidget {
  final EmployeeStatus? status;
  final VoidCallback? onRefresh;

  const StatusDisplay({super.key, this.status, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.person_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Enter Employee ID to check status',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with employee info and refresh button
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status?.employeeName ?? 'Unknown Employee',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Status',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Status message
            if (status!.message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: status!.actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: status!.actionColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status!.actionIcon,
                      color: status!.actionColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status!.message,
                        style: TextStyle(
                          color: status!.actionColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Current status info
            if (status!.currentStatus != null) _buildStatusInfo(context),

            // Time information
            if (status!.checkInTime != null || status!.checkOutTime != null)
              _buildTimeInfo(context),

            // Late request information
            if (status!.isWaitingForApproval == true ||
                status!.requestId != null)
              _buildLateRequestInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(BuildContext context) {
    String statusText = status!.statusDisplayText;
    Color statusColor;
    IconData statusIcon;

    // Determine status color and icon
    if (statusText.toLowerCase().contains('present')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (statusText.toLowerCase().contains('late')) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else if (statusText.toLowerCase().contains('absent')) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Status: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          // Check-in time
          if (status!.checkInTime != null)
            Row(
              children: [
                const Icon(Icons.login, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Check-in: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${_formatCurrentDate()} ${status!.formattedCheckInTime}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),

          // Check-out time
          if (status!.checkOutTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Check-out: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${_formatCurrentDate()} ${status!.formattedCheckOutTime}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Work duration
            if (status!.workDuration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    status!.workDuration!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLateRequestInfo(BuildContext context) {
    if (status!.isWaitingForApproval != true && status!.requestId == null) {
      return const SizedBox.shrink();
    }

    Color requestColor;
    IconData requestIcon;
    String requestText;

    if (status!.isWaitingForApproval == true) {
      requestColor = Colors.orange;
      requestIcon = Icons.hourglass_top;
      requestText = 'Late request pending approval';
    } else if (status!.isRequestRejected == true) {
      requestColor = Colors.red;
      requestIcon = Icons.cancel;
      requestText = 'Late request rejected';
    } else {
      requestColor = Colors.green;
      requestIcon = Icons.check_circle;
      requestText = 'Late request approved';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: requestColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: requestColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(requestIcon, color: requestColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requestText,
                  style: TextStyle(
                    color: requestColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (status!.requestId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Request ID: ${status!.requestId}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],

          if (status!.requestedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Submitted: ${status!.requestedAt}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
