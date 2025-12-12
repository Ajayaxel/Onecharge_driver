import 'package:flutter/material.dart';
import 'package:onecharge_d/core/models/ticket.dart';
import 'package:onecharge_d/presentation/service/google_map_widget.dart';

class TicketDetailsScreen extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailsScreen({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final greenColor = const Color(0xFF0E7B00);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ticket Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.ticketId,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(ticket.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: greenColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Map Section
              SizedBox(
                height: 200,
                width: double.infinity,
                child: GoogleMapWidget(
                  latitude: ticket.latitude,
                  longitude: ticket.longitude,
                  location: ticket.location,
                ),
              ),
              const SizedBox(height: 20),
              
              // Issue Details Card
              _buildInfoCard(
                title: 'Issue Details',
                children: [
                  _buildInfoRow(
                    icon: Icons.build_outlined,
                    label: 'Issue Type',
                    value: ticket.issueCategory.name,
                  ),
                  if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: ticket.description!,
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Vehicle Information Card
              _buildInfoCard(
                title: 'Vehicle Information',
                children: [
                  _buildInfoRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Vehicle',
                    value: '${ticket.brand.name} ${ticket.model.name}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Number Plate',
                    value: ticket.numberPlate,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.category_outlined,
                    label: 'Vehicle Type',
                    value: ticket.vehicleType.name,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Location Card
              _buildInfoCard(
                title: 'Location',
                children: [
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: ticket.location,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Work Time Card (if available)
              if (ticket.workTime != null)
                _buildInfoCard(
                  title: 'Work Information',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: greenColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: greenColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Work Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.workTime!.calculatedFormattedTime,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: greenColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ticket.workTime!.startTime != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.play_circle_outline,
                        label: 'Started',
                        value: _formatDateTime(ticket.workTime!.startTime!),
                      ),
                    ],
                    if (ticket.workTime!.endTime != null) ...[
                      const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    value: _formatDateTime(ticket.workTime!.endTime!),
                  ),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              
              // Before Work Attachments Section (if available)
              if (ticket.beforeWorkAttachments.isNotEmpty)
                _buildInfoCard(
                  title: 'Before Work Attachments',
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ticket.beforeWorkAttachments.map((attachment) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            attachment.fileUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              if (ticket.beforeWorkAttachments.isNotEmpty)
                const SizedBox(height: 16),
              
              // After Work Attachments Section (if available)
              if (ticket.afterWorkAttachments.isNotEmpty)
                _buildInfoCard(
                  title: 'After Work Attachments',
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ticket.afterWorkAttachments.map((attachment) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            attachment.fileUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}

