// GET /users/{id} returns a NESTED object:
// {
//   "id": 1, "name": "...", "username": "...", "email": "...",
//   "address": { "street": "...", "city": "...", "geo": { "lat": "...", "lng": "..." } },
//   "phone": "...", "website": "...",
//   "company": { "name": "...", "catchPhrase": "...", "bs": "..." }
// }
//
// Address and Company are small classes of their own rather than flattened
// fields on User — this is the standard way to model nested JSON: each
// nested object in the API response gets its own fromJson(), and the
// parent's fromJson() just calls the child's.
//This file defines the data structure for a User and teaches the app how to convert API JSON into Dart objects.
//Instead of storing everything inside one huge User class, every nested JSON object gets its own class.
//Every JSON object becomes a Dart class, and every class knows how to build itself using fromJson()."

class Geo {
  final String lat;
  final String lng;

  Geo({required this.lat, required this.lng});

  factory Geo.fromJson(Map<String, dynamic> json) {
    return Geo(lat: json['lat'] ?? '', lng: json['lng'] ?? '');
  }
}

class Address {
  final String street;
  final String city;
  final String zipcode;
  final Geo geo;

  Address({required this.street, required this.city, required this.zipcode, required this.geo});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      zipcode: json['zipcode'] ?? '',
      // Nested-within-nested: geo is itself an object, so we recurse one
      // level deeper and call Geo.fromJson() on it.
      geo: Geo.fromJson(json['geo'] ?? {}),
    );
  }
}

class Company {
  final String name;
  final String catchPhrase;

  Company({required this.name, required this.catchPhrase});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] ?? '',
      catchPhrase: json['catchPhrase'] ?? '',
    );
  }
}

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final Address address;
  final Company company;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
    required this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      // Each nested object gets passed to its own fromJson — this is what
      // keeps User.fromJson() readable instead of one giant flat function.
      address: Address.fromJson(json['address'] ?? {}),
      company: Company.fromJson(json['company'] ?? {}),
    );
  }
}