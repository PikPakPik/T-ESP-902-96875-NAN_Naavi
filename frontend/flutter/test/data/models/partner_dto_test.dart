import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/data/models/partner_dto.dart';

void main() {
  group('PartnerDto', () {
    test('should create PartnerDto with all fields', () {
      final partner = PartnerDto(
        id: 1,
        name: 'Test Partner',
        category: 'Category',
        address: '123 Test St',
        testimonial: 'Great service',
        logoUrl: 'https://example.com/logo.png',
        logoText: 'TEST',
      );

      expect(partner.id, 1);
      expect(partner.name, 'Test Partner');
      expect(partner.category, 'Category');
      expect(partner.address, '123 Test St');
      expect(partner.testimonial, 'Great service');
      expect(partner.logoUrl, 'https://example.com/logo.png');
      expect(partner.logoText, 'TEST');
    });

    test('should create PartnerDto with optional fields as null', () {
      final partner = PartnerDto(
        id: 1,
        name: 'Test Partner',
        category: 'Category',
        address: '123 Test St',
      );

      expect(partner.testimonial, isNull);
      expect(partner.logoUrl, isNull);
      expect(partner.logoText, isNull);
    });

    test('should create PartnerDto from JSON', () {
      final json = {
        'id': 1,
        'name': 'Test Partner',
        'category': 'Category',
        'address': '123 Test St',
        'testimonial': 'Great service',
        'logoUrl': 'https://example.com/logo.png',
        'logoText': 'TEST',
      };

      final partner = PartnerDto.fromJson(json);

      expect(partner.id, 1);
      expect(partner.name, 'Test Partner');
      expect(partner.category, 'Category');
      expect(partner.address, '123 Test St');
      expect(partner.testimonial, 'Great service');
      expect(partner.logoUrl, 'https://example.com/logo.png');
      expect(partner.logoText, 'TEST');
    });

    test('should create PartnerDto from JSON with null optional fields', () {
      final json = {
        'id': 1,
        'name': 'Test Partner',
        'category': 'Category',
        'address': '123 Test St',
      };

      final partner = PartnerDto.fromJson(json);

      expect(partner.id, 1);
      expect(partner.name, 'Test Partner');
      expect(partner.testimonial, isNull);
      expect(partner.logoUrl, isNull);
      expect(partner.logoText, isNull);
    });
  });
}
