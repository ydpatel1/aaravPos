import '../domain/booking_repository.dart';
import '../domain/service_item.dart';
import '../domain/slot_item.dart';
import '../domain/staff_member.dart';

class BookingRepositoryImpl implements BookingRepository {
  @override
  Future<bool> checkConsent(String customerName) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return customerName.isNotEmpty;
  }

  @override
  Future<List<ServiceItem>> fetchServices() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      ServiceItem(
        id: '1',
        name: 'Eyebrow Classic Tint',
        category: 'Pet Grooming',
        durationMin: 30,
        price: 50,
      ),
      ServiceItem(
        id: '2',
        name: 'Anti-Aging Facial',
        category: 'Skin Care / Facial Services',
        durationMin: 75,
        price: 120,
        consentRequired: true,
      ),
      ServiceItem(
        id: '3',
        name: 'Signature Facial',
        category: 'Skin Care / Facial Services',
        durationMin: 60,
        price: 95,
        consentRequired: true,
      ),
      ServiceItem(
        id: '4',
        name: 'Express Facial',
        category: 'Skin Care / Facial Services',
        durationMin: 30,
        price: 60,
        consentRequired: true,
      ),
      ServiceItem(
        id: '5',
        name: 'Hydrating Facial',
        category: 'Skin Care / Facial Services',
        durationMin: 60,
        price: 105,
        consentRequired: true,
      ),
    ];
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
    const names = ['shivani patel', 'rohan sharma', 'priya jain', 'aditi patel'];
    if (query.isEmpty) {
      return names;
    }
    return names
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<String> submitBooking() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'BK-${DateTime.now().millisecondsSinceEpoch}';
  }
}
