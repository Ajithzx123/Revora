import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';

class MakeInfo {
  final String name;
  final List<String> models;
  const MakeInfo(this.name, this.models);
}

/// Pick-lists for forms. The backend is the source of truth (it validates against
/// the same lists); the bundled copy keeps demo mode and flaky networks working.
class MasterData {
  final List<MakeInfo> makes;
  final List<String> fuels;
  final List<String> transmissions;
  final List<String> bodyTypes;
  final List<String> colors;
  final List<String> cities;
  final int minBudget;
  final int maxBudget;
  final int minYear;

  const MasterData({
    required this.makes,
    required this.fuels,
    required this.transmissions,
    required this.bodyTypes,
    required this.colors,
    required this.cities,
    this.minBudget = 100000,
    this.maxBudget = 50000000,
    this.minYear = 2000,
  });

  List<String> get makeNames => [for (final m in makes) m.name];

  List<String> modelsOf(String? make) {
    for (final m in makes) {
      if (m.name == make) return m.models;
    }
    return const [];
  }

  factory MasterData.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) => [for (final v in (json[key] as List)) v as String];
    final limits = (json['limits'] as Map?) ?? const {};
    return MasterData(
      makes: [
        for (final m in (json['makes'] as List))
          MakeInfo(
            (m as Map)['name'] as String,
            [for (final model in (m['models'] as List)) model as String],
          ),
      ],
      fuels: strings('fuels'),
      transmissions: strings('transmissions'),
      bodyTypes: strings('body_types'),
      colors: strings('colors'),
      cities: strings('cities'),
      minBudget: (limits['min_budget'] as int?) ?? 100000,
      maxBudget: (limits['max_budget'] as int?) ?? 50000000,
      minYear: (limits['min_year'] as int?) ?? 2000,
    );
  }

  /// Mirrors backend/app/core/master_data.py (used offline and in demo mode).
  static const bundled = MasterData(
    makes: [
      MakeInfo('Maruti Suzuki', ['Alto K10', 'Swift', 'Baleno', 'Dzire', 'WagonR', 'Celerio', 'Brezza', 'Ertiga', 'Fronx', 'Grand Vitara', 'S-Presso']),
      MakeInfo('Hyundai', ['i10 Nios', 'i20', 'Aura', 'Venue', 'Exter', 'Creta', 'Verna', 'Alcazar']),
      MakeInfo('Tata', ['Tiago', 'Tigor', 'Altroz', 'Punch', 'Nexon', 'Harrier', 'Safari']),
      MakeInfo('Mahindra', ['Bolero', 'XUV 3XO', 'Scorpio', 'Thar', 'XUV700']),
      MakeInfo('Honda', ['Amaze', 'City', 'Elevate']),
      MakeInfo('Toyota', ['Glanza', 'Urban Cruiser Hyryder', 'Innova Crysta', 'Fortuner', 'Hilux']),
      MakeInfo('Kia', ['Sonet', 'Seltos', 'Carens']),
      MakeInfo('Renault', ['Kwid', 'Triber', 'Kiger']),
      MakeInfo('Volkswagen', ['Polo', 'Virtus', 'Taigun']),
      MakeInfo('Skoda', ['Slavia', 'Kushaq']),
      MakeInfo('MG', ['Comet EV', 'Astor', 'Hector', 'ZS EV']),
      MakeInfo('Nissan', ['Magnite']),
      MakeInfo('Jeep', ['Compass']),
    ],
    fuels: ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'],
    transmissions: ['Manual', 'Automatic'],
    bodyTypes: ['Hatchback', 'Sedan', 'SUV', 'MUV', 'Coupe', 'Convertible'],
    colors: ['White', 'Silver', 'Grey', 'Black', 'Red', 'Blue', 'Brown', 'Green', 'Orange', 'Yellow', 'Beige', 'Other'],
    cities: [
      'Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad', 'Chennai', 'Pune', 'Kolkata', 'Ahmedabad',
      'Jaipur', 'Surat', 'Lucknow', 'Kochi', 'Chandigarh', 'Indore', 'Nagpur', 'Coimbatore',
      'Visakhapatnam', 'Bhopal', 'Patna', 'Vadodara', 'Gurugram', 'Noida', 'Thane', 'Navi Mumbai',
    ],
  );
}

/// Live: ask the backend, fall back to the bundled lists if it is unreachable.
final masterDataProvider = FutureProvider<MasterData>((ref) async {
  if (AppConfig.instance.useMockData) return MasterData.bundled;
  try {
    final res = await ref.watch(dioProvider).get('/master-data');
    return MasterData.fromJson(res.data as Map<String, dynamic>);
  } on DioException {
    return MasterData.bundled;
  }
});
