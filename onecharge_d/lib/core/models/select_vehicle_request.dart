class SelectVehicleRequest {
  final String vehicleNumber;

  SelectVehicleRequest({
    required this.vehicleNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_number': vehicleNumber,
    };
  }
}

