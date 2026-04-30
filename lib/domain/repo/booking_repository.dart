import 'package:aaravpos/domain/model/consent_check_result.dart';
import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/signed_consent_data.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';

abstract class BookingRepository {
  Future<List<ServiceItem>> fetchServices();
  Future<List<StaffMember>> fetchStaff();
  Future<List<SlotItem>> fetchSlots(String staffId, DateTime date);
  Future<List<Customer>> searchCustomers(String phoneNumber);

  /// GET concent/check/{customerId}/{consentFormId}?serviceId={serviceId}
  Future<ConsentCheckResult> checkConsentStatus({
    required String customerId,
    required String consentFormId,
    required String serviceId,
  });

  /// POST appointment or POST appointment/checkin.
  /// Returns a map with at minimum { 'appointmentId': String, 'customerId': String }.
  Future<Map<String, dynamic>> submitBooking({
    required SessionState session,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    List<SignedConsentData> signedConsents,
  });

  /// POST concent/customer-sign — called after booking when consent is needed.
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
