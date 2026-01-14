import 'package:image_picker/image_picker.dart';

class DropOffVehicleRequest {
  final double latitude;
  final double longitude;
  final List<XFile> images;
  final List<String> sides;
  final XFile? driverSeatedImage; // Optional image if car has issues

  DropOffVehicleRequest({
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.sides,
    this.driverSeatedImage,
  });

  // Validate that images and sides match
  bool isValid() {
    if (images.length != sides.length) {
      return false;
    }
    if (images.length != 6) {
      return false;
    }
    // Validate sides are correct and unique
    final validSides = ['front', 'back', 'left', 'right', 'top', 'bottom'];
    final lowerSides = sides.map((s) => s.toLowerCase()).toList();
    
    // Check all sides are valid
    for (final side in lowerSides) {
      if (!validSides.contains(side)) {
        return false;
      }
    }
    
    // Check for duplicates
    if (lowerSides.toSet().length != lowerSides.length) {
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'images_count': images.length,
      'sides': sides,
      'has_driver_seated_image': driverSeatedImage != null,
    };
  }
}

