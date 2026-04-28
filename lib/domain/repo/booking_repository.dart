import 'package:aaravpos/domain/model/consent_check_result.dart';
import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';

abstract class BookingRepository {
  Future<List<ServiceItem>> fetchServices();
  Future<List<StaffMember>> fetchStaff();
  Future<List<SlotItem>> fetchSlots(String staffId, DateTime date);
  Future<List<Customer>> searchCustomers(String phoneNumber);

  Future<ConsentCheckResult> checkConsentStatus({
    required String customerId,
    required String consentFormId,
    required String serviceId,
  });

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
  });

  /// POST appointment or POST appointment/checkin.
  /// Returns the appointmentId from the response.
  Future<String> submitBooking({
    required SessionState session,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  });

  /// POST consent/customer-sign — called after booking when consent is needed.
  Future<void> signConsentAfterBooking({
    required String tenantId,
    required String appointmentId,
    required String customerId,
    required List<String> serviceIds,
    required String outletId,
    required String consentFormId,
    required String staffId,
    required String signatureType,
    String? imageUrl,
    String? typedName,
    bool isChecked,
  });
}
