import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_bloc.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_event.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_state.dart';
import 'package:onecharge_d/presentation/service/google_map_widget.dart';
import 'package:onecharge_d/presentation/service/task_completion_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedFiles = []; // For before_work attachments
  List<XFile> _selectedAfterWorkFiles = []; // For after_work attachments
  bool _isUploadingFromButton = false;
  int? _pendingUploadTicketId;
  bool _beforeWorkUploadSuccess = false; // Track before_work upload success
  String? _lastUploadType; // Track the last upload type
  bool _startWorkSuccess = false; // Track start work success

  @override
  void initState() {
    super.initState();
    print('\n🚀 [SCREEN] ServiceRequestScreen initialized');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 Fetching tickets on screen load...');
    // Fetch tickets when screen loads
    context.read<TicketBloc>().add(const FetchTickets());
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {bool isAfterWork = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isAfterWork) {
            _selectedAfterWorkFiles.add(image);
          } else {
            _selectedFiles.add(image);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source, {bool isAfterWork = false}) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
      );
      if (video != null) {
        setState(() {
          if (isAfterWork) {
            _selectedAfterWorkFiles.add(video);
          } else {
            _selectedFiles.add(video);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog({bool isAfterWork = false}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isAfterWork: isAfterWork);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isAfterWork: isAfterWork);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoSourceDialog({bool isAfterWork = false}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video Library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery, isAfterWork: isAfterWork);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera, isAfterWork: isAfterWork);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeAfterWorkFile(int index) {
    setState(() {
      _selectedAfterWorkFiles.removeAt(index);
    });
  }

  void _uploadBeforeWorkAttachments(int ticketId) {
    print('\n👤 [USER ACTION] Upload Before Work Attachments');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎫 Ticket ID: $ticketId');
    print('📁 Selected Files: ${_selectedFiles.length}');
    
    if (_selectedFiles.isEmpty) {
      print('⚠️  [WARNING] No files selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to upload'),
        ),
      );
      return;
    }

    print('✅ Triggering upload...');
    // Reset the flag before upload and track upload type
    setState(() {
      _beforeWorkUploadSuccess = false;
      _lastUploadType = 'before_work';
    });
    // Upload before_work attachments
    context.read<TicketBloc>().add(
      UploadAttachments(
        ticketId: ticketId,
        files: _selectedFiles,
        attachmentType: 'before_work',
      ),
    );
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  void _uploadAfterWorkAttachments(int ticketId) {
    print('\n👤 [USER ACTION] Upload After Work Attachments');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎫 Ticket ID: $ticketId');
    print('📁 Selected Files: ${_selectedAfterWorkFiles.length}');
    
    if (_selectedAfterWorkFiles.isEmpty) {
      print('⚠️  [WARNING] No files selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to upload'),
        ),
      );
      return;
    }

    print('✅ Triggering upload...');
    // Upload after_work attachments
    context.read<TicketBloc>().add(
      UploadAttachments(
        ticketId: ticketId,
        files: _selectedAfterWorkFiles,
        attachmentType: 'after_work',
      ),
    );
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  bool _isVideoFile(XFile file) {
    final path = file.path.toLowerCase();
    final mimeType = file.mimeType?.toLowerCase() ?? '';
    return mimeType.startsWith('video/') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm');
  }

  void _showNavigationOptions(String latitude, String longitude, String location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text(
                  'Select Navigation App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),),
                const SizedBox(height: 20),
                // Google Maps
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Google Maps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openGoogleMaps(latitude, longitude, location);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                // Apple Maps
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Apple Maps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openAppleMaps(latitude, longitude, location);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                // Waze
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Color(0xFF5C9EFF),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Waze',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openWaze(latitude, longitude, location);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
             
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGoogleMaps(String? latitude, String? longitude, String location) async {
    try {
      if (latitude == null || longitude == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location coordinates not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${Uri.encodeComponent(location)}',
      );
      
      if (await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAppleMaps(String latitude, String longitude, String location) async {
    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      
      final appleMapsUrl = Uri.parse(
        Platform.isIOS
            ? 'http://maps.apple.com/?daddr=$lat,$lng'
            : 'http://maps.apple.com/?daddr=$lat,$lng',
      );
      
      if (await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Apple Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Apple Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWaze(String latitude, String longitude, String location) async {
    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      
      // Waze URL format: waze://?ll=latitude,longitude&navigate=yes
      final wazeUrl = Uri.parse(
        'waze://?ll=$lat,$lng&navigate=yes',
      );
      
      // Try Waze app first
      if (await launchUrl(wazeUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      // Fallback to Waze web if app is not installed
      final wazeWebUrl = Uri.parse(
        'https://waze.com/ul?ll=$lat,$lng&navigate=yes',
      );
      
      if (await launchUrl(wazeWebUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Waze'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Waze: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<TicketBloc, TicketState>(
          listener: (context, state) {
            print('\n🎧 [UI LISTENER] State Changed');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('📊 State Type: ${state.runtimeType}');
            
            if (state is TicketUploadSuccess) {
              print('✅ [SUCCESS] Upload successful');
              print('💬 Message: ${state.message}');
              
              // If uploading from Complete Work button (after_work), complete work after upload success
              if (_isUploadingFromButton && _pendingUploadTicketId != null) {
                final ticketIdToComplete = _pendingUploadTicketId!;
                print('🔄 Upload was from Complete Work button, triggering complete work...');
                print('🎫 Ticket ID to complete: $ticketIdToComplete');
                
                // Clear selected files
                setState(() {
                  _selectedAfterWorkFiles.clear();
                });
                
                // Complete work after upload success
                context.read<TicketBloc>().add(
                  CompleteWork(ticketId: ticketIdToComplete),
                );
                
                print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
                return;
              }
              
              // Check if this was a before_work upload
              if (_lastUploadType == 'before_work') {
                setState(() {
                  _beforeWorkUploadSuccess = true;
                  _selectedFiles.clear();
                  _lastUploadType = null;
                });
                print('✅ Before work upload successful, Start button will be shown');
              } else {
                // Clear selected files after successful upload
                setState(() {
                  _selectedFiles.clear();
                  _selectedAfterWorkFiles.clear();
                  _lastUploadType = null;
                });
              }
            } else if (state is TicketUploadError) {
              print('❌ [ERROR] Upload failed');
              print('💬 Message: ${state.message}');
              print('📱 Showing error snackbar');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is CompleteWorkSuccess) {
              print('✅ [SUCCESS] Complete work successful');
              print('💬 Message: ${state.message}');
              print('📊 Ticket Status: ${state.ticket.status}');
              
              // Reset flags
              setState(() {
                _isUploadingFromButton = false;
                _pendingUploadTicketId = null;
                _selectedAfterWorkFiles.clear();
              });
              
              // Navigate to completion screen
              print('🔄 Navigating to completion screen...');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskCompletionScreen(
                    ticket: state.ticket,
                    message: state.message,
                  ),
                ),
              );
            } else if (state is CompleteWorkError) {
              print('❌ [ERROR] Complete work failed');
              print('💬 Message: ${state.message}');
              // Reset flags on error
              setState(() {
                _isUploadingFromButton = false;
                _pendingUploadTicketId = null;
              });
              print('📱 Showing error snackbar');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is StartWorkSuccess) {
              print('✅ [SUCCESS] Start work successful');
              print('💬 Message: ${state.message}');
              print('📊 Ticket Status: ${state.ticket.status}');
              print('📱 Showing success snackbar');
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Set flag to show "Completed" button
              setState(() {
                _startWorkSuccess = true;
                _beforeWorkUploadSuccess = false;
              });
              // Refresh tickets to get updated status
              print('🔄 Refreshing tickets...');
              context.read<TicketBloc>().add(const FetchTickets());
            } else if (state is StartWorkError) {
              print('❌ [ERROR] Start work failed');
              print('💬 Message: ${state.message}');
              print('📱 Showing error snackbar');
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          },
          child: BlocBuilder<TicketBloc, TicketState>(
            builder: (context, state) {
              if (state is TicketLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is TicketError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${state.message}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.read<TicketBloc>().add(const FetchTickets());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is TicketLoaded) {
              final tickets = state.tickets;
              
              if (tickets.isEmpty) {
                return const Center(
                  child: Text(
                    'No tickets available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                );
              }

              // Use the first ticket for display
              final ticket = tickets[0];
              final statusLower = ticket.status.toLowerCase();
              
              // Reset the flags if status is "active" or "in_progress" (work has already started)
              // Use case-insensitive comparison to handle "Active" vs "active"
              if (statusLower == "active" || statusLower == "in_progress") {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _beforeWorkUploadSuccess = false;
                      _startWorkSuccess = false;
                    });
                  }
                });
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Incoming Service Request ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 177,
                        width: double.infinity,
                        child: GoogleMapWidget(
                          latitude: ticket.latitude,
                          longitude: ticket.longitude,
                          location: ticket.location,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (ticket.latitude != null && ticket.longitude != null) {
                              _showNavigationOptions(
                                ticket.latitude!,
                                ticket.longitude!,
                                ticket.location,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Location coordinates not available'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'See Routes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Issue Type",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xff9A9A9A), thickness: 1),
                      const SizedBox(height: 10),
                      SizedBox(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Issue Type",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const SizedBox(height: 8),
                                  Text(
                                    ticket.issueCategory.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      ticket.description!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "5 min",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Show customer attachment if available, otherwise show placeholder
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: ticket.customerAttachments.isNotEmpty
                                  ? Image.network(
                                      ticket.customerAttachments[0].fileUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          width: 120,
                                          height: 120,
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
                                        return Image.asset(
                                          'images/home/issue.png',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'images/home/issue.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xff9A9A9A), thickness: 1),
                      const Text(
                        "Customer Notes & Media",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Show customer notes & media card only if description or attachments exist
                      if ((ticket.description != null && ticket.description!.isNotEmpty) ||
                          ticket.customerAttachments.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer description/notes
                              if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                                Text(
                                  ticket.description!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    height: 1.4,
                                  ),
                                ),
                                if (ticket.customerAttachments.isNotEmpty)
                                  const SizedBox(height: 12),
                              ],
                              // Customer attachments (images)
                              if (ticket.customerAttachments.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final attachmentsToShow = ticket.customerAttachments.take(2).toList();
                                    return Row(
                                      children: [
                                        ...attachmentsToShow.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final attachment = entry.value;
                                          final isLast = index == attachmentsToShow.length - 1;
                                          return Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: isLast ? 0 : 8,
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  attachment.fileUrl,
                                                  height: 100,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) {
                                                      return child;
                                                    }
                                                    return Container(
                                                      height: 100,
                                                      width: double.infinity,
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
                                                      height: 100,
                                                      width: double.infinity,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Show before_work section only when status is not "active" or "in_progress"
                      if (statusLower != "active" && statusLower != "in_progress") ...[
                        const Text(
                          "Vehicle Documentation",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xff9A9A9A), thickness: 1),
                        const SizedBox(height: 10),
                        Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Please upload photos or videos of the vehicle before starting the work.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Upload buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showImageSourceDialog,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 22,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add Photo',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showVideoSourceDialog,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.videocam_outlined,
                                              size: 22,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add Video',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Display selected files
                            if (_selectedFiles.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Text(
                                    'Selected Media',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_selectedFiles.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _selectedFiles.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  final isVideo = _isVideoFile(file);
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: isVideo
                                              ? Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.asset(
                                                      'images/home/issue.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Container(
                                                      color: Colors.black.withOpacity(0.3),
                                                    ),
                                                    const Center(
                                                      child: Icon(
                                                        Icons.play_circle_filled,
                                                        color: Colors.white,
                                                        size: 45,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Image.file(
                                                  File(file.path),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeFile(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                              // Upload button
                              Builder(
                                builder: (context) {
                                  final uploadState = context.watch<TicketBloc>().state;
                                  final isUploading = uploadState is TicketLoaded 
                                      ? uploadState.isUploading 
                                      : uploadState is TicketUploading;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isUploading
                                          ? null
                                          : () => _uploadBeforeWorkAttachments(ticket.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xff0E7B00),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        disabledBackgroundColor: Colors.grey[400],
                                      ),
                                      child: isUploading
                                          ? const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Uploading...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'Upload Attachments',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      ],
                      // Show after_work section when status is "active" or "in_progress"
                      if (statusLower == "active" || statusLower == "in_progress") ...[
                        const SizedBox(height: 20),
                        const Text(
                          "Completed Work Documentation",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xff9A9A9A), thickness: 1),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Please upload photos or videos of the completed work. After uploading, click the Complete Work button to finish the job.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Upload buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showImageSourceDialog(isAfterWork: true),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0xFFE0E0E0),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate_outlined,
                                                size: 22,
                                                color: Colors.black,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Photo',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showVideoSourceDialog(isAfterWork: true),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0xFFE0E0E0),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.videocam_outlined,
                                                size: 22,
                                                color: Colors.black,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Video',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Display selected after_work files
                              if (_selectedAfterWorkFiles.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Text(
                                      'Selected Media',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_selectedAfterWorkFiles.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _selectedAfterWorkFiles.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final file = entry.value;
                                    final isVideo = _isVideoFile(file);
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 110,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE0E0E0),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: isVideo
                                                ? Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Image.asset(
                                                        'images/home/issue.png',
                                                        fit: BoxFit.cover,
                                                      ),
                                                      Container(
                                                        color: Colors.black.withOpacity(0.3),
                                                      ),
                                                      const Center(
                                                        child: Icon(
                                                          Icons.play_circle_filled,
                                                          color: Colors.white,
                                                          size: 45,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Image.file(
                                                    File(file.path),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeAfterWorkFile(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    spreadRadius: 1,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                                // Upload after_work button
                                Builder(
                                  builder: (context) {
                                    final uploadState = context.watch<TicketBloc>().state;
                                    final isUploading = uploadState is TicketLoaded 
                                        ? uploadState.isUploading 
                                        : uploadState is TicketUploading;
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isUploading
                                            ? null
                                            : () => _uploadAfterWorkAttachments(ticket.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xff0E7B00),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          disabledBackgroundColor: Colors.grey[400],
                                        ),
                                        child: isUploading
                                            ? const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Uploading...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Text(
                                                'Upload Completed Work',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Show Start button ONLY when status is NOT "active" or "in_progress" (always visible when not active/in_progress)
                      // IMPORTANT: This button should NEVER show when status is "active" or "in_progress"
                      if (statusLower != "active" && statusLower != "in_progress")
                        BlocBuilder<TicketBloc, TicketState>(
                          builder: (context, blocState) {
                            final isStartingWork = blocState is TicketLoading || 
                                (blocState is StartWorkSuccess);
                            
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (isStartingWork || _startWorkSuccess || !_beforeWorkUploadSuccess)
                                    ? null
                                    : () {
                                        print('\n👤 [USER ACTION] Start Button Clicked');
                                        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                                        print('🎫 Ticket ID: ${ticket.id}');
                                        print('📊 Current Status: ${ticket.status}');
                                        // Call start work API
                                        context.read<TicketBloc>().add(
                                          StartWork(ticketId: ticket.id),
                                        );
                                        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (_startWorkSuccess || !_beforeWorkUploadSuccess)
                                      ? Colors.grey[400]
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                                child: isStartingWork
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Starting...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _startWorkSuccess ? 'Completed' : 'Start',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      // Show Complete button when status is "active" or "in_progress"
                      if (statusLower == "active" || statusLower == "in_progress")
                        BlocBuilder<TicketBloc, TicketState>(
                          builder: (context, blocState) {
                            final isCompletingWork = blocState is TicketLoading || 
                                (blocState is CompleteWorkSuccess) ||
                                (blocState is TicketUploading && _isUploadingFromButton);
                            
                            return GestureDetector(
                              onTap: isCompletingWork
                                  ? null
                                  : () {
                                      print('\n👤 [USER ACTION] Complete Work Button Clicked');
                                      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                                      print('🎫 Ticket ID: ${ticket.id}');
                                      print('📁 After Work Files Selected: ${_selectedAfterWorkFiles.length}');
                                      
                                      // If files are selected, upload first then complete work
                                      if (_selectedAfterWorkFiles.isNotEmpty) {
                                        print('📤 Uploading files first, then completing work...');
                                        setState(() {
                                          _isUploadingFromButton = true;
                                          _pendingUploadTicketId = ticket.id;
                                        });
                                        _uploadAfterWorkAttachments(ticket.id);
                                      } else {
                                        print('✅ No files, directly completing work...');
                                        // Directly complete work
                                        context.read<TicketBloc>().add(
                                          CompleteWork(ticketId: ticket.id),
                                        );
                                      }
                                      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
                                    },
                              child: Container(
                                height: 45,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isCompletingWork
                                      ? Colors.grey[400]
                                      : Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: isCompletingWork
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              "Completing...",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "I completed my work",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            }

            // Initial state
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
        ),
      ),
    );
  }
}
