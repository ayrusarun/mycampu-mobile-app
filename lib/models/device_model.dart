/// Device models for push notification management
class DeviceRegisterRequest {
  final String token;
  final String platform;
  final String? deviceName;

  DeviceRegisterRequest({
    required this.token,
    required this.platform,
    this.deviceName,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'platform': platform,
        if (deviceName != null) 'device_name': deviceName,
      };
}

class DeviceResponse {
  final int id;
  final int userId;
  final String deviceToken;
  final String platform;
  final String? deviceName;
  final bool isActive;
  final DateTime lastUsedAt;
  final DateTime createdAt;

  DeviceResponse({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.platform,
    this.deviceName,
    required this.isActive,
    required this.lastUsedAt,
    required this.createdAt,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      id: json['id'],
      userId: json['user_id'],
      deviceToken: json['device_token'],
      platform: json['platform'],
      deviceName: json['device_name'],
      isActive: json['is_active'],
      lastUsedAt: DateTime.parse(json['last_used_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'device_token': deviceToken,
        'platform': platform,
        'device_name': deviceName,
        'is_active': isActive,
        'last_used_at': lastUsedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class DeviceUnregisterRequest {
  final int? deviceId;
  final String? deviceToken;

  DeviceUnregisterRequest({
    this.deviceId,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() => {
        if (deviceId != null) 'device_id': deviceId,
        if (deviceToken != null) 'device_token': deviceToken,
      };
}
