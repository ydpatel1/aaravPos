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
  Future<List<SlotItem>> fetchSlots(DateTime? date) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const [
      SlotItem(time: '10:45 AM', period: 'Morning'),
      SlotItem(time: '11:00 AM', period: 'Morning'),
      SlotItem(time: '11:15 AM', period: 'Morning'),
      SlotItem(time: '11:30 AM', period: 'Morning'),
      SlotItem(time: '12:00 PM', period: 'Afternoon'),
      SlotItem(time: '12:15 PM', period: 'Afternoon'),
      SlotItem(time: '12:30 PM', period: 'Afternoon'),
      SlotItem(time: '12:45 PM', period: 'Afternoon'),
      SlotItem(time: '1:00 PM', period: 'Afternoon'),
      SlotItem(time: '5:00 PM', period: 'Evening'),
      SlotItem(time: '5:15 PM', period: 'Evening'),
      SlotItem(time: '5:30 PM', period: 'Evening'),
    ];
  }

  @override
  Future<List<StaffMember>> fetchStaff() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const [
      StaffMember(id: 's1', name: 'Harshil Patel'),
      StaffMember(id: 's2', name: 'Arial A'),
      StaffMember(id: 's3', name: 'Ali M'),
      StaffMember(id: 's4', name: 'chloe C'),
      StaffMember(id: 's5', name: 'Ayaan B'),
    ];
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
