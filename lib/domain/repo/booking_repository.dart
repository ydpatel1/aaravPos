import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';

abstract class BookingRepository {
  Future<List<ServiceItem>> fetchServices();

  Future<List<StaffMember>> fetchStaff();

  Future<List<SlotItem>> fetchSlots(String staffId, DateTime date);

  Future<List<Customer>> searchCustomers(String phoneNumber);

  Future<bool> checkConsent(String customerName);

  Future<String> submitBooking();
}
