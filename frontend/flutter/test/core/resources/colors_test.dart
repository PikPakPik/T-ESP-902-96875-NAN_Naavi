// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/resources/colors.dart';

void main() {
  group('AppColors', () {
    test('primaryColor should be correct hex value', () {
      expect(AppColors.primaryColor, equals(const Color(0xFF241913)));
    });

    test('secondaryColor should be correct hex value', () {
      expect(AppColors.secondaryColor, equals(const Color(0xFF324943)));
    });

    test('tertiaryColor should be correct hex value', () {
      expect(AppColors.tertiaryColor, equals(const Color(0xFFE6F2E2)));
    });

    test('colors should have proper opacity', () {
      expect(AppColors.primaryColor.opacity, equals(1.0));
      expect(AppColors.secondaryColor.opacity, equals(1.0));
      expect(AppColors.tertiaryColor.opacity, equals(1.0));
    });

    test('primaryColor should have correct RGB values', () {
      expect(AppColors.primaryColor.r, closeTo(0x24 / 255.0, 0.01));
      expect(AppColors.primaryColor.g, closeTo(0x19 / 255.0, 0.01));
      expect(AppColors.primaryColor.b, closeTo(0x13 / 255.0, 0.01));
    });

    test('secondaryColor should have correct RGB values', () {
      expect(AppColors.secondaryColor.r, closeTo(0x32 / 255.0, 0.01));
      expect(AppColors.secondaryColor.g, closeTo(0x49 / 255.0, 0.01));
      expect(AppColors.secondaryColor.b, closeTo(0x43 / 255.0, 0.01));
    });

    test('tertiaryColor should have correct RGB values', () {
      expect(AppColors.tertiaryColor.r, closeTo(0xE6 / 255.0, 0.01));
      expect(AppColors.tertiaryColor.g, closeTo(0xF2 / 255.0, 0.01));
      expect(AppColors.tertiaryColor.b, closeTo(0xE2 / 255.0, 0.01));
    });

    test('all colors should be distinct', () {
      expect(AppColors.primaryColor, isNot(equals(AppColors.secondaryColor)));
      expect(AppColors.primaryColor, isNot(equals(AppColors.tertiaryColor)));
      expect(AppColors.secondaryColor, isNot(equals(AppColors.tertiaryColor)));
    });
  });
}
