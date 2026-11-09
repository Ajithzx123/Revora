import '../../../../shared/domain/entities/vehicle.dart';

/// What the dealer fills in when adding or editing a car.
class VehicleDraft {
  String? registrationNo;
  String? make;
  String? model;
  String? variant;
  int? year;
  String? fuel;
  String? transmission;
  int? km;
  int owners;
  String? color;
  String? bodyType;
  int? price;
  int? minPrice;
  String? description;

  VehicleDraft({
    this.registrationNo,
    this.make,
    this.model,
    this.variant,
    this.year,
    this.fuel,
    this.transmission,
    this.km,
    this.owners = 1,
    this.color,
    this.bodyType,
    this.price,
    this.minPrice,
    this.description,
  });

  factory VehicleDraft.from(Vehicle v) => VehicleDraft(
    registrationNo: v.registrationNo,
    make: v.make,
    model: v.model,
    variant: v.variant,
    year: v.year,
    fuel: v.fuelType,
    transmission: v.transmission,
    km: v.mileage,
    owners: v.owners,
    color: v.color,
    bodyType: v.bodyType,
    price: v.price.round(),
    minPrice: v.minPrice?.round(),
    description: v.description,
  );

  String? _clean(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Every field is sent (nulls included) so an edit can clear optional fields.
  Map<String, dynamic> toJson() => {
    'registration_no': registrationNo,
    'make': make,
    'model': model,
    'variant': _clean(variant),
    'year': year,
    'fuel': fuel,
    'transmission': transmission,
    'km': km,
    'owners': owners,
    'color': color,
    'body_type': bodyType,
    'price': price,
    'min_price': minPrice,
    'description': _clean(description),
  };
}
