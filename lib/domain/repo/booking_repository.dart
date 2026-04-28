import 'package:aaravpos/domain/model/consent_check_result.dart';
import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';

abstract class BookingRepository {
  Future<List<ServiceItem>> fetchServices();

  Future<List<StaffMember>> fetchStaff();

  Future<List<SlotItem>> fetchSlots(String staffId, DateTime date);

  Future<List<Customer>> searchCustomers(String phoneNumber);

  /// GET consent/check/{customerId}/{consentFormId}?serviceId={serviceId}
  Future<ConsentCheckResult> checkConsentStatus({
    required String customerId,
    required String consentFormId,
    required String serviceId,
  });

  /// POST consent/customer-sign
  Future<void> signConsent({
    required String customerId,
    required String consentFormId,
    required List<String> serviceIds,
    required String staffId,
    required String outletId,
    required String tenantId,
    required String signatureType,
    String? imageUrl, // for SIGNATURE_IMAGE
    String? typedName, // for TYPED_NAME
  });

  Future<String> submitBooking();
}
