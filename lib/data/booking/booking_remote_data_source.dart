import '../../core/network/api_service.dart';
import '../../domain/model/customer.dart';
import '../../domain/model/service_item.dart';
import '../../domain/model/slot_item.dart';
import '../../domain/model/staff_member.dart';

class BookingRemoteDataSource {
  BookingRemoteDataSource(this._apiService);

  final ApiService _apiService;

  /// GET service/categories/tenant/$tenantId
  ///   ?available_online=true&is_available_online_category=true
  ///
  /// Expected response shape:
  /// {
  ///   "success": true,
  ///   "message": "OK",
  ///   "data": {
  ///     "categories": [
  ///       {
  ///         "id": "cat-1",
  ///         "name": "Skin Care",
  ///         "services": [
  ///           {
  ///             "id": "s1",
  ///             "name": "Facial",
  ///             "price": 50,
  ///             "min_price": null,
  ///             "max_price": null,
  ///             "price_mode": "FIXED",
  ///             "estimated_time": 30,
  ///             "requires_consent": false,
  ///             "consent_form_id": null
  ///           }
  ///         ]
  ///       }
  ///     ]
  ///   }
  /// }
  Future<List<ServiceItem>> fetchServices({required String tenantId}) async {
    try {
      final response = await _apiService.get(
        'service/categories/tenant/$tenantId',
        queryParameters: <String, dynamic>{
          'available_online': true,
          'is_available_online_category': true,
        },
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response format: expected Map<String, dynamic>',
        );
      }

      if (body['success'] == false) {
        final errorMsg =
            body['message'] as String? ?? 'Failed to fetch services';
        throw Exception(errorMsg);
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format: expected Map with categories');
      }

      final categories = data['categories'];
      if (categories is! List) {
        throw Exception('Invalid categories format: expected List');
      }

      final items = <ServiceItem>[];
      for (final category in categories) {
        if (category is! Map<String, dynamic>) {
          continue;
        }

        final categoryName = category['name'] as String? ?? '';
        final categoryId = category['id'] as String? ?? '';

        if (categoryName.isEmpty || categoryId.isEmpty) {
          continue;
        }

        final services = category['services'];
        if (services is! List) {
          continue;
        }

        for (final service in services) {
          if (service is! Map<String, dynamic>) {
            continue;
          }

          try {
            items.add(
              ServiceItem.fromJson(
                service,
                categoryName: categoryName,
                categoryId: categoryId,
              ),
            );
          } catch (e) {
            // Skip malformed service items
            continue;
          }
        }
      }

      if (items.isEmpty) {
        throw Exception('No services found in response');
      }

      return items;
    } catch (e) {
      throw Exception('Failed to fetch services: ${e.toString()}');
    }
  }

  /// GET staff/outlet/$outletId
  ///
  /// Expected response shape:
  /// {
  ///   "success": true,
  ///   "message": "Staff retrieved successfully",
  ///   "data": [
  ///     {
  ///       "id": "...",
  ///       "staffDetails": {
  ///         "firstName": "Harshil",
  ///         "lastName": "Patel",
  ///         "staff_type": "Barber"
  ///       }
  ///     }
  ///   ]
  /// }
  Future<List<StaffMember>> fetchStaff({required String outletId}) async {
    try {
      final response = await _apiService.get('staff/outlet/$outletId');

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response format: expected Map<String, dynamic>',
        );
      }

      if (body['success'] == false) {
        final errorMsg = body['message'] as String? ?? 'Failed to fetch staff';
        throw Exception(errorMsg);
      }

      final data = body['data'];
      if (data is! List) {
        throw Exception('Invalid data format: expected List');
      }

      final items = <StaffMember>[];
      for (final staff in data) {
        if (staff is! Map<String, dynamic>) {
          continue;
        }

        try {
          final staffDetails = staff['staffDetails'] as Map<String, dynamic>?;
          if (staffDetails == null) {
            continue;
          }

          items.add(
            StaffMember(
              id: staff['id'] as String? ?? '',
              firstName: staffDetails['firstName'] as String? ?? '',
              lastName: staffDetails['lastName'] as String? ?? '',
              role: staffDetails['staff_type'] as String? ?? '',
              color: staffDetails['color'] as String?,
              image: staffDetails['image'] as String?,
            ),
          );
        } catch (e) {
          // Skip malformed staff items
          continue;
        }
      }

      if (items.isEmpty) {
        throw Exception('No staff members found');
      }

      return items;
    } catch (e) {
      throw Exception('Failed to fetch staff: ${e.toString()}');
    }
  }

  /// GET staff/slots/$staffId?date=$dateStr
  ///
  /// New API Response Structure:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "groups": {
  ///       "morning": [...],
  ///       "afternoon": [...],
  ///       "evening": [...]
  ///     }
  ///   }
  /// }
  Future<List<SlotItem>> fetchSlots({
    required String staffId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiService.get(
        'staff/slots/$staffId',
        queryParameters: <String, dynamic>{'date': dateStr},
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected Map');
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('No data in response');
      }

      final groups = data['groups'] as Map<String, dynamic>?;
      if (groups == null) {
        throw Exception('No groups in response');
      }

      final items = <SlotItem>[];

      // Parse slots from all groups (morning, afternoon, evening)
      for (final groupKey in ['morning', 'afternoon', 'evening']) {
        final groupSlots = groups[groupKey];
        if (groupSlots is List) {
          for (final slot in groupSlots) {
            if (slot is! Map<String, dynamic>) continue;
            try {
              items.add(SlotItem.fromJson(slot));
            } catch (e) {
              continue;
            }
          }
        }
      }

      return items;
    } catch (e) {
      throw Exception('Failed to fetch slots: ${e.toString()}');
    }
  }

  /// GET customer/list/$tenantId?page=1&limit=20&search=$encodedPhone
  ///
  /// Search customers by phone number (without country code)
  /// Response: { "success": true, "data": { "data": [ { "id": "...", "first_name": "...", "last_name": "...", "phone": "...", "email": "..." } ] } }
  Future<List<Customer>> searchCustomers({
    required String tenantId,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.get(
        'customer/list/$tenantId',
        queryParameters: <String, dynamic>{
          'page': 1,
          'limit': 20,
          'search': Uri.encodeComponent(phoneNumber),
        },
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected Map');
      }

      // API returns nested structure: { data: { data: [...] } }
      final outerData = body['data'];
      if (outerData is! Map<String, dynamic>) {
        return []; // No data
      }

      final innerData = outerData['data'];
      if (innerData is! List) {
        return []; // No customers found
      }

      final customers = <Customer>[];
      for (final customer in innerData) {
        if (customer is! Map<String, dynamic>) continue;
        try {
          customers.add(Customer.fromJson(customer));
        } catch (e) {
          continue;
        }
      }

      return customers;
    } catch (e) {
      throw Exception('Failed to search customers: ${e.toString()}');
    }
  }

  /// GET concent/check/{customerId}/{consentFormId}?serviceId={serviceId}
  /// Note: API uses "concent" (typo in their API — must match exactly)
  Future<Map<String, dynamic>> checkConsentStatus({
    required String customerId,
    required String consentFormId,
    required String serviceId,
  }) async {
    try {
      final response = await _apiService.get(
        'concent/check/$customerId/$consentFormId',
        queryParameters: <String, dynamic>{'serviceId': serviceId},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid consent check response');
      }
      return body;
    } catch (e) {
      throw Exception('Failed to check consent: ${e.toString()}');
    }
  }

  /// POST consent/customer-sign
  Future<void> signConsent({
    required String customerId,
    required String consentFormId,
    required List<String> serviceIds,
    required String staffId,
    required String outletId,
    required String tenantId,
    required String signatureType,
    String? imageUrl,
    String? typedName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'tenantId': tenantId,
        'customerId': customerId,
        'serviceIds': serviceIds,
        'outletId': outletId,
        'consentFormId': consentFormId,
        'signatureType': signatureType,
        'channel': 'POS',
        'staffId': staffId,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (typedName != null) 'typedName': typedName,
      };
      final response = await _apiService.post(
        'consent/customer-sign',
        data: payload,
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['success'] == false) {
        throw Exception(body['message'] as String? ?? 'Consent sign failed');
      }
    } catch (e) {
      throw Exception('Failed to sign consent: ${e.toString()}');
    }
  }

  /// POST appointment — book a future appointment
  /// Payload matches spec §8 exactly.
  Future<Map<String, dynamic>> submitAppointment({
    required bool isCheckIn,
    required String staffId,
    required String outletId,
    required String tenantId,
    required List<String> serviceIds,
    required List<String> slotIds,
    required String date,
    required String startTime,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    bool requiresConsent = false,
  }) async {
    try {
      final endpoint = isCheckIn ? 'appointment/checkin' : 'appointment';

      // Check-in payload (spec §8.1) — no gender/date_of_birth
      // Appointment payload (spec §8.2) — includes gender/date_of_birth
      final customerPayload = <String, dynamic>{
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.isNotEmpty ? email : null,
        'phone': phone, // full phone e.g. "+1XXXXXXXXXX"
        if (!isCheckIn) 'gender': '',
        if (!isCheckIn) 'date_of_birth': '',
      };

      final payload = <String, dynamic>{
        'tenantId': tenantId,
        'outletId': outletId,
        'staffId': staffId,
        'serviceIds': serviceIds,
        'slotIds': slotIds,
        'date': date,
        'startTime': startTime,
        'customer': customerPayload,
        if (!isCheckIn) 'isWalkIn': false,
        // Spec §8.2: only add requiresConsent when enforcementMode == 'FIXED'
        if (requiresConsent) 'requiresConsent': true,
      };

      final response = await _apiService.post(endpoint, data: payload);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        if (body['success'] == false) {
          throw Exception(body['message'] as String? ?? 'Booking failed');
        }
        final data = body['data'] as Map<String, dynamic>?;
        final appointmentId =
            data?['id'] as String? ??
            data?['appointmentId'] as String? ??
            body['id'] as String? ??
            'BK-${DateTime.now().millisecondsSinceEpoch}';
        final customerId =
            data?['customerId'] as String? ?? '';
        return {
          'appointmentId': appointmentId,
          'customerId': customerId,
          'apiResponse': body,
        };
      }
      return {
        'appointmentId': 'BK-${DateTime.now().millisecondsSinceEpoch}',
        'customerId': '',
        'apiResponse': body,
      };
    } catch (e) {
      throw Exception('Failed to submit booking: ${e.toString()}');
    }
  }

  /// POST concent/customer-sign — API #5
  /// Note: API uses "concent" (typo in their API — must match exactly).
  /// Called AFTER booking to attach the signed consent to the appointment.
  Future<void> signConsentWithAppointment({
    required String tenantId,
    required String appointmentId,
    required String customerId,
    required List<String> serviceIds,
    required String outletId,
    required String consentFormId,
    required String staffId,
    required String signatureType,
    String? imageUrl, // base64 PNG data URI — for SIGNATURE_IMAGE
    String? typedName, // for TYPED_NAME
    bool isChecked = false, // for CHECKBOX_ONLY
  }) async {
    try {
      final payload = <String, dynamic>{
        'tenantId': tenantId,
        'appointmentId': appointmentId,
        'customerId': customerId,
        'serviceIds': serviceIds,
        'outletId': outletId,
        'concentFormId': consentFormId, // API uses "concentFormId" (typo in their API)
        'signatureType': signatureType,
        'channel': 'POS',
        'staffId': staffId,
        if (signatureType == 'SIGNATURE_IMAGE' && imageUrl != null)
          'imageUrl': imageUrl,
        if (signatureType == 'TYPED_NAME' && typedName != null)
          'typedName': typedName,
        if (signatureType == 'CHECKBOX_ONLY') 'isChecked': isChecked,
      };

      final response = await _apiService.post(
        'concent/customer-sign',
        data: payload,
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['success'] == false) {
        throw Exception(body['message'] as String? ?? 'Consent sign failed');
      }
    } catch (e) {
      throw Exception('Failed to sign consent: ${e.toString()}');
    }
  }
}
