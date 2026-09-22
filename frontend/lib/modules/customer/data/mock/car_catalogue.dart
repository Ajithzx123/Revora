import 'package:flutter/material.dart';

class CarBrand {
  final String name;
  final String code;
  final bool isPopular;
  final IconData? icon;

  const CarBrand({
    required this.name,
    required this.code,
    this.isPopular = false,
    this.icon,
  });
}

class CarModelInfo {
  final String name;
  final String category; // SUV, Sedan, Hatchback, etc.
  final String startingPrice;
  final List<String> variants;

  const CarModelInfo({
    required this.name,
    required this.category,
    required this.startingPrice,
    required this.variants,
  });
}

class CarCatalogue {
  CarCatalogue._();

  static const List<CarBrand> brands = [
    // Popular
    CarBrand(name: 'Toyota', code: 'toyota', isPopular: true, icon: Icons.directions_car_filled),
    CarBrand(name: 'BMW', code: 'bmw', isPopular: true, icon: Icons.electric_car),
    CarBrand(name: 'Mercedes', code: 'mercedes', isPopular: true, icon: Icons.stars_rounded),
    CarBrand(name: 'Audi', code: 'audi', isPopular: true, icon: Icons.sports_motorsports),
    CarBrand(name: 'Tesla', code: 'tesla', isPopular: true, icon: Icons.bolt),
    CarBrand(name: 'Honda', code: 'honda', isPopular: true, icon: Icons.directions_car),
    CarBrand(name: 'Hyundai', code: 'hyundai', isPopular: true, icon: Icons.drive_eta),
    CarBrand(name: 'Tata', code: 'tata', isPopular: true, icon: Icons.shield),
    CarBrand(name: 'Mahindra', code: 'mahindra', isPopular: true, icon: Icons.terrain),

    // All alphabetical
    CarBrand(name: 'Acura', code: 'acura'),
    CarBrand(name: 'Alfa Romeo', code: 'alfaromeo'),
    CarBrand(name: 'Aston Martin', code: 'astonmartin'),
    CarBrand(name: 'Audi', code: 'audi'),
    CarBrand(name: 'Bentley', code: 'bentley'),
    CarBrand(name: 'BMW', code: 'bmw'),
    CarBrand(name: 'Bugatti', code: 'bugatti'),
    CarBrand(name: 'BYD', code: 'byd'),
    CarBrand(name: 'Cadillac', code: 'cadillac'),
    CarBrand(name: 'Chevrolet', code: 'chevrolet'),
    CarBrand(name: 'Citroen', code: 'citroen'),
    CarBrand(name: 'Ferrari', code: 'ferrari'),
    CarBrand(name: 'Ford', code: 'ford'),
    CarBrand(name: 'Genesis', code: 'genesis'),
    CarBrand(name: 'Honda', code: 'honda'),
    CarBrand(name: 'Hyundai', code: 'hyundai'),
    CarBrand(name: 'Jaguar', code: 'jaguar'),
    CarBrand(name: 'Jeep', code: 'jeep'),
    CarBrand(name: 'Kia', code: 'kia'),
    CarBrand(name: 'Lamborghini', code: 'lamborghini'),
    CarBrand(name: 'Land Rover', code: 'landrover'),
    CarBrand(name: 'Lexus', code: 'lexus'),
    CarBrand(name: 'Mahindra', code: 'mahindra'),
    CarBrand(name: 'Maruti Suzuki', code: 'marutisuzuki'),
    CarBrand(name: 'Maserati', code: 'maserati'),
    CarBrand(name: 'Mazda', code: 'mazda'),
    CarBrand(name: 'Mercedes-Benz', code: 'mercedes'),
    CarBrand(name: 'MG', code: 'mg'),
    CarBrand(name: 'Mini', code: 'mini'),
    CarBrand(name: 'Nissan', code: 'nissan'),
    CarBrand(name: 'Porsche', code: 'porsche'),
    CarBrand(name: 'Renault', code: 'renault'),
    CarBrand(name: 'Rolls-Royce', code: 'rollsroyce'),
    CarBrand(name: 'Skoda', code: 'skoda'),
    CarBrand(name: 'Tata', code: 'tata'),
    CarBrand(name: 'Tesla', code: 'tesla'),
    CarBrand(name: 'Toyota', code: 'toyota'),
    CarBrand(name: 'Volkswagen', code: 'volkswagen'),
    CarBrand(name: 'Volvo', code: 'volvo'),
  ];

  static final Map<String, List<CarModelInfo>> modelsByBrand = {
    'Toyota': [
      CarModelInfo(name: 'Innova Crysta', category: 'MPV', startingPrice: '₹19.99 L', variants: ['GX 7 STR', 'GX 8 STR', 'VX 7 STR', 'ZX 7 STR']),
      CarModelInfo(name: 'Fortuner', category: 'Premium SUV', startingPrice: '₹33.43 L', variants: ['4x2 MT', '4x2 AT', '4x4 MT', '4x4 AT', 'GR-Sport']),
      CarModelInfo(name: 'Urban Cruiser Hyryder', category: 'Compact SUV', startingPrice: '₹11.14 L', variants: ['E', 'S', 'G', 'V', 'Hybrid G', 'Hybrid V']),
      CarModelInfo(name: 'Glanza', category: 'Hatchback', startingPrice: '₹6.86 L', variants: ['E', 'S', 'G', 'V']),
      CarModelInfo(name: 'Camry', category: 'Sedan', startingPrice: '₹46.17 L', variants: ['Hybrid 2.5']),
    ],
    'Hyundai': [
      CarModelInfo(name: 'Creta', category: 'SUV', startingPrice: '₹11.00 L', variants: ['E', 'EX', 'S', 'S(O)', 'SX', 'SX Tech', 'SX(O) Turbo']),
      CarModelInfo(name: 'Venue', category: 'Compact SUV', startingPrice: '₹7.94 L', variants: ['E', 'S', 'S(O)', 'SX', 'SX(O)']),
      CarModelInfo(name: 'i20', category: 'Premium Hatchback', startingPrice: '₹7.04 L', variants: ['Era', 'Magna', 'Sportz', 'Asta', 'Asta (O)']),
      CarModelInfo(name: 'Verna', category: 'Sedan', startingPrice: '₹11.00 L', variants: ['EX', 'S', 'SX', 'SX(O) Turbo']),
      CarModelInfo(name: 'Tucson', category: 'Premium SUV', startingPrice: '₹29.02 L', variants: ['Platinum AT', 'Signature AT', 'Signature AWD']),
    ],
    'BMW': [
      CarModelInfo(name: '3 Series Gran Limousine', category: 'Sedan', startingPrice: '₹60.60 L', variants: ['330Li M Sport', '320Ld M Sport']),
      CarModelInfo(name: 'X1', category: 'Compact Luxury SUV', startingPrice: '₹49.50 L', variants: ['sDrive18i xLine', 'sDrive18d M Sport']),
      CarModelInfo(name: 'X5', category: 'Luxury SUV', startingPrice: '₹96.00 L', variants: ['xDrive40i xLine', 'xDrive40i M Sport', 'xDrive30d M Sport']),
      CarModelInfo(name: '5 Series', category: 'Executive Sedan', startingPrice: '₹72.90 L', variants: ['530Li M Sport']),
    ],
    'Mercedes': [
      CarModelInfo(name: 'C-Class', category: 'Sedan', startingPrice: '₹61.85 L', variants: ['C 200', 'C 220d', 'C 300 AMG Line']),
      CarModelInfo(name: 'GLA', category: 'Compact SUV', startingPrice: '₹51.75 L', variants: ['GLA 200', 'GLA 220d 4MATIC', 'AMG GLA 35 4MATIC']),
      CarModelInfo(name: 'GLC', category: 'Luxury SUV', startingPrice: '₹75.90 L', variants: ['GLC 300 4MATIC', 'GLC 220d 4MATIC']),
      CarModelInfo(name: 'E-Class', category: 'Executive Sedan', startingPrice: '₹78.50 L', variants: ['E 200 Exclusive', 'E 220d Exclusive']),
    ],
    'Mercedes-Benz': [
      CarModelInfo(name: 'C-Class', category: 'Sedan', startingPrice: '₹61.85 L', variants: ['C 200', 'C 220d', 'C 300 AMG Line']),
      CarModelInfo(name: 'GLA', category: 'Compact SUV', startingPrice: '₹51.75 L', variants: ['GLA 200', 'GLA 220d 4MATIC', 'AMG GLA 35 4MATIC']),
      CarModelInfo(name: 'GLC', category: 'Luxury SUV', startingPrice: '₹75.90 L', variants: ['GLC 300 4MATIC', 'GLC 220d 4MATIC']),
    ],
    'Audi': [
      CarModelInfo(name: 'A4', category: 'Sedan', startingPrice: '₹45.34 L', variants: ['Premium', 'Premium Plus', 'Technology']),
      CarModelInfo(name: 'Q3', category: 'Compact SUV', startingPrice: '₹43.81 L', variants: ['Premium', 'Premium Plus', 'Technology', 'Sportback']),
      CarModelInfo(name: 'A6', category: 'Executive Sedan', startingPrice: '₹64.41 L', variants: ['Premium Plus', 'Technology']),
      CarModelInfo(name: 'Q7', category: 'Luxury SUV', startingPrice: '₹88.66 L', variants: ['Premium Plus', 'Technology']),
    ],
    'Tesla': [
      CarModelInfo(name: 'Model 3', category: 'Electric Sedan', startingPrice: '₹60.00 L', variants: ['Standard Range Plus', 'Long Range AWD', 'Performance']),
      CarModelInfo(name: 'Model Y', category: 'Electric SUV', startingPrice: '₹70.00 L', variants: ['Long Range AWD', 'Performance']),
      CarModelInfo(name: 'Model S', category: 'Electric Luxury Sedan', startingPrice: '₹1.50 Cr', variants: ['Dual Motor AWD', 'Plaid']),
    ],
    'Tata': [
      CarModelInfo(name: 'Nexon', category: 'Compact SUV', startingPrice: '₹8.00 L', variants: ['Smart', 'Pure', 'Creative', 'Fearless', 'Fearless+ S']),
      CarModelInfo(name: 'Harrier', category: 'Mid SUV', startingPrice: '₹15.49 L', variants: ['Smart', 'Pure', 'Adventure', 'Fearless+']),
      CarModelInfo(name: 'Safari', category: '7-Seater SUV', startingPrice: '₹16.19 L', variants: ['Smart', 'Pure', 'Adventure', 'Accomplished+']),
      CarModelInfo(name: 'Punch', category: 'Micro SUV', startingPrice: '₹6.13 L', variants: ['Pure', 'Adventure', 'Accomplished', 'Creative']),
      CarModelInfo(name: 'Curvv', category: 'Coupe SUV', startingPrice: '₹9.99 L', variants: ['Smart', 'Pure+', 'Creative+', 'Accomplished+']),
    ],
    'Mahindra': [
      CarModelInfo(name: 'Thar', category: 'Off-Road SUV', startingPrice: '₹11.35 L', variants: ['AX(O) Hard Top', 'LX Hard Top', 'Roxx MX1', 'Roxx AX7L']),
      CarModelInfo(name: 'Scorpio-N', category: 'SUV', startingPrice: '₹13.85 L', variants: ['Z2', 'Z4', 'Z6', 'Z8', 'Z8L']),
      CarModelInfo(name: 'XUV700', category: 'Premium SUV', startingPrice: '₹13.99 L', variants: ['MX', 'AX3', 'AX5', 'AX7', 'AX7 Luxury']),
      CarModelInfo(name: 'XUV 3XO', category: 'Compact SUV', startingPrice: '₹7.49 L', variants: ['MX1', 'MX2 Pro', 'AX5', 'AX7 Luxury']),
    ],
    'Honda': [
      CarModelInfo(name: 'City', category: 'Sedan', startingPrice: '₹12.08 L', variants: ['SV', 'V', 'VX', 'ZX', 'e:HEV Hybrid']),
      CarModelInfo(name: 'Elevate', category: 'Mid SUV', startingPrice: '₹11.69 L', variants: ['SV', 'V', 'VX', 'ZX']),
      CarModelInfo(name: 'Amaze', category: 'Compact Sedan', startingPrice: '₹7.16 L', variants: ['E', 'S', 'VX']),
    ],
    'Maruti Suzuki': [
      CarModelInfo(name: 'Swift', category: 'Hatchback', startingPrice: '₹6.49 L', variants: ['LXi', 'VXi', 'ZXi', 'ZXi+']),
      CarModelInfo(name: 'Brezza', category: 'Compact SUV', startingPrice: '₹8.34 L', variants: ['LXi', 'VXi', 'ZXi', 'ZXi+']),
      CarModelInfo(name: 'Grand Vitara', category: 'Hybrid SUV', startingPrice: '₹10.99 L', variants: ['Sigma', 'Delta', 'Zeta', 'Alpha', 'Intelligent Hybrid']),
      CarModelInfo(name: 'Baleno', category: 'Premium Hatchback', startingPrice: '₹6.66 L', variants: ['Sigma', 'Delta', 'Zeta', 'Alpha']),
      CarModelInfo(name: 'Fronx', category: 'Crossover', startingPrice: '₹7.51 L', variants: ['Sigma', 'Delta', 'Zeta Turbo', 'Alpha Turbo']),
    ],
    'Kia': [
      CarModelInfo(name: 'Seltos', category: 'SUV', startingPrice: '₹10.90 L', variants: ['HTE', 'HTK', 'HTX', 'GTX+', 'X-Line']),
      CarModelInfo(name: 'Sonet', category: 'Compact SUV', startingPrice: '₹7.99 L', variants: ['HTE', 'HTK', 'HTX', 'GTX+']),
      CarModelInfo(name: 'Carens', category: 'MPV', startingPrice: '₹10.52 L', variants: ['Premium', 'Prestige', 'Luxury', 'Luxury Plus']),
    ],
  };

  static List<CarModelInfo> getModelsForBrand(String brand) {
    if (modelsByBrand.containsKey(brand)) {
      return modelsByBrand[brand]!;
    }
    // Generic fallback for any other brand
    return [
      CarModelInfo(
        name: '$brand Standard',
        category: 'Vehicle',
        startingPrice: '₹15.00 L',
        variants: ['Base', 'Mid-Level', 'Top-End Spec'],
      ),
      CarModelInfo(
        name: '$brand Sport',
        category: 'Performance',
        startingPrice: '₹25.00 L',
        variants: ['Sport Edition', 'Pro Performance'],
      ),
    ];
  }
}
