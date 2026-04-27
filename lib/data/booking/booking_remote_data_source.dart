import '../../core/network/api_service.dart';
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
      if (body is! List)
        throw Exception('Invalid response format: expected List');
      final items = <SlotItem>[];
      for (final slot in body) {
        if (slot is! Map<String, dynamic>) continue;
        try {
          items.add(SlotItem.fromJson(slot));
        } catch (e) {
          continue;
        }
      }
      return items;
    } catch (e) {
      throw Exception('Failed to fetch slots: ${e.toString()}');
    }
  }
}
