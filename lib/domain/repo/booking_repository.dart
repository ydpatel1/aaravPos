

import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';

abstract class BookingRepository {
  Future<List<ServiceItem>> fetchServices();

  Future<List<StaffMember>> fetchStaff();

  Future<List<SlotItem>> fetchSlots(DateTime? date);

  Future<List<String>> searchCustomers(String query);

  Future<bool> checkConsent(String customerName);

  Future<String> submitBooking();
}
