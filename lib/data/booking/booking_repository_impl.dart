import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/domain/model/consent_check_result.dart';
import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/signed_consent_data.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';

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
  Future<List<Customer>> searchCustomers(String phoneNumber) async {
    final tenantId = await _secureStorage.getTenantId();
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Tenant ID not found. Please log in again.');
    }
    return _remoteDataSource.searchCustomers(
      tenantId: tenantId,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<ConsentCheckResult> checkConsentStatus({
    required String customerId,
    required String consentFormId,
    required String serviceId,
  }) async {
    final raw = await _remoteDataSource.checkConsentStatus(
      customerId: customerId,
      consentFormId: consentFormId,
      serviceId: serviceId,
    );
    return ConsentCheckResult.fromJson(raw, serviceId: serviceId);
  }

  @override
  Future<Map<String, dynamic>> submitBooking({
    required SessionState session,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    List<SignedConsentData> signedConsents = const [],
  }) async {
    final outletId = await _secureStorage.getOutletId() ?? '';
    final tenantId = await _secureStorage.getTenantId() ?? '';

    final staffId = session.selectedStaff?.id ?? '';
    final serviceIds = session.selectedServices.map((s) => s.id).toList();
    final slotIds = session.selectedSlot != null
        ? [session.selectedSlot!.id]
        : <String>[];
    final startTime = session.selectedSlot?.startTime ?? '';
    final isCheckIn = session.mode == BookingMode.checkIn;

    final date = session.selectedDate != null
        ? '${session.selectedDate!.year}-'
              '${session.selectedDate!.month.toString().padLeft(2, '0')}-'
              '${session.selectedDate!.day.toString().padLeft(2, '0')}'
        : '';

    // Spec §8.2: add requiresConsent=true only when any service has enforcementMode == 'FIXED'
    final requiresConsent = session.selectedServices.any(
      (s) => s.consentRule?.enforcementMode == 'FIXED',
    );

    return _remoteDataSource.submitAppointment(
      isCheckIn: isCheckIn,
      staffId: staffId,
      outletId: outletId,
      tenantId: tenantId,
      serviceIds: serviceIds,
      slotIds: slotIds,
      date: date,
      startTime: startTime,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      requiresConsent: requiresConsent,
    );
  }

  @override
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
    bool isChecked = false,
  }) async {
    return _remoteDataSource.signConsentWithAppointment(
      tenantId: tenantId,
      appointmentId: appointmentId,
      customerId: customerId,
      serviceIds: serviceIds,
      outletId: outletId,
      consentFormId: consentFormId,
      staffId: staffId,
      signatureType: signatureType,
      imageUrl: imageUrl,
      typedName: typedName,
      isChecked: isChecked,
    );
  }
}
