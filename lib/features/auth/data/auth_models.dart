/// Data model representing the authenticated user.
///
/// This model is built from the backend auth profile response.
class UserModel {
  final String id;
  final String firebaseUid;

  final String? email;
  final String? phone;

  final String fullName;
  final String gender;

  final String collegeName;
  final String rollNumber;

  final String role;

  final bool approved;
  final bool blocked;

  /// Coins the student can spend in the store.
  final int coinBalance;

  /// Delivery address saved from the student's last redemption, or null if
  /// they have never redeemed anything. Used to prefill the redeem form.
  final SavedAddress? savedAddress;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.collegeName,
    required this.rollNumber,
    required this.role,
    required this.approved,
    required this.blocked,
    this.coinBalance = 0,
    this.savedAddress,
  });

  /// Creates a [UserModel] from the JSON payload returned by the backend.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['fullName'],
      gender: json['gender'],
      collegeName: json['collegeName'],
      rollNumber: json['rollNumber'],
      role: json['role'],
      approved: json['approved'],
      blocked: json['blocked'],
      coinBalance: (json['coinBalance'] as num?)?.toInt() ?? 0,
      savedAddress: SavedAddress.fromUserJson(json),
    );
  }

  UserModel copyWith({
    String? email,
    String? phone,
    String? fullName,
    String? gender,
    String? collegeName,
    String? rollNumber,
    String? role,
    bool? approved,
    bool? blocked,
    int? coinBalance,
    SavedAddress? savedAddress,
  }) {
    return UserModel(
      id: id,
      firebaseUid: firebaseUid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      collegeName: collegeName ?? this.collegeName,
      rollNumber: rollNumber ?? this.rollNumber,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      blocked: blocked ?? this.blocked,
      coinBalance: coinBalance ?? this.coinBalance,
      savedAddress: savedAddress ?? this.savedAddress,
    );
  }
}

/// The delivery address the backend keeps on the user (`saved*` fields),
/// updated each time the student redeems an item.
class SavedAddress {
  final String? recipientName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? contactPhone;

  const SavedAddress({
    this.recipientName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.contactPhone,
  });

  /// Reads the `saved*` fields from a user payload. Returns null when none of
  /// them are set, i.e. the student has never saved an address.
  static SavedAddress? fromUserJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final address = SavedAddress(
      recipientName: read('savedRecipientName'),
      addressLine1: read('savedAddressLine1'),
      addressLine2: read('savedAddressLine2'),
      city: read('savedCity'),
      state: read('savedState'),
      postalCode: read('savedPostalCode'),
      country: read('savedCountry'),
      contactPhone: read('savedContactPhone'),
    );

    return address._isEmpty ? null : address;
  }

  bool get _isEmpty => [
    recipientName,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
    contactPhone,
  ].every((field) => field == null);
}
