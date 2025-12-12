class WorkTime {
  final int id;
  final String? startTime;
  final String? endTime;
  final String status;
  final int totalPausedSeconds;
  final String formattedTime;
  final int totalSeconds;

  WorkTime({
    required this.id,
    this.startTime,
    this.endTime,
    required this.status,
    required this.totalPausedSeconds,
    required this.formattedTime,
    required this.totalSeconds,
  });

  factory WorkTime.fromJson(Map<String, dynamic> json) {
    return WorkTime(
      id: json['id'] ?? 0,
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'] ?? '',
      totalPausedSeconds: json['total_paused_seconds'] ?? 0,
      formattedTime: json['formatted_time'] ?? '0:00',
      totalSeconds: json['total_seconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'total_paused_seconds': totalPausedSeconds,
      'formatted_time': formattedTime,
      'total_seconds': totalSeconds,
    };
  }

  /// Calculates the formatted work time from start and end times
  /// Returns the calculated time if both start and end times are available,
  /// otherwise returns the formattedTime from the API
  /// Format: "10h 25m" for hours, "25m" for minutes only, "30s" for seconds only
  String get calculatedFormattedTime {
    if (startTime != null && endTime != null) {
      try {
        final start = DateTime.parse(startTime!);
        final end = DateTime.parse(endTime!);
        final difference = end.difference(start);
        
        // Subtract paused time if available
        final totalSeconds = difference.inSeconds - totalPausedSeconds;
        
        if (totalSeconds < 0) {
          return '0m';
        }
        
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;
        
        // Format: Show hours and minutes if hours > 0
        if (hours > 0) {
          if (minutes > 0) {
            return '${hours}h ${minutes}m';
          } else {
            return '${hours}h';
          }
        } else if (minutes > 0) {
          // Show only minutes if less than 1 hour
          return '${minutes}m';
        } else {
          // Show seconds if less than 1 minute
          return '${seconds}s';
        }
      } catch (e) {
        // If parsing fails, return the API's formattedTime
        return formattedTime;
      }
    }
    
    // If totalSeconds is available and valid, use it
    if (totalSeconds > 0) {
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;
      
      // Format: Show hours and minutes if hours > 0
      if (hours > 0) {
        if (minutes > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${hours}h';
        }
      } else if (minutes > 0) {
        // Show only minutes if less than 1 hour
        return '${minutes}m';
      } else {
        // Show seconds if less than 1 minute
        return '${seconds}s';
      }
    }
    
    // Fallback to API's formattedTime
    return formattedTime;
  }
}

