import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';

import 'booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remoteDataSource, this._secureStorage);

  final BookingRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  @override
  Future<List<ServiceItem>> fetchServices() async {
    final tenantId = await _secureStorage.getTenantId();
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Tenant ID not found. Please log in again.');
    }
    return _remoteDataSource.fetchServices(tenantId: tenantId);
  }

  @override
  Future<bool> checkConsent(String customerName) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return customerName.isNotEmpty;
  }

  @override
  Future<List<SlotItem>> fetchSlots(String staffId, DateTime date) async {
    return _remoteDataSource.fetchSlots(staffId: staffId, date: date);
  }

  @override
  Future<List<StaffMember>> fetchStaff() async {
    final outletId = await _secureStorage.getOutletId();
    if (outletId == null || outletId.isEmpty) {
      throw Exception('Outlet ID not found. Please log in again.');
    }
    return _remoteDataSource.fetchStaff(outletId: outletId);
  }

  @override
  Future<List<String>> searchCustomers(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    const names = [
      'shivani patel',
      'rohan sharma',
      'priya jain',
      'aditi patel',
    ];
    if (query.isEmpty) return names;
    return names
        .where((n) => n.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<String> submitBooking() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'BK-${DateTime.now().millisecondsSinceEpoch}';
  }
}
