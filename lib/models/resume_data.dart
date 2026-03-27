import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'profile_link.dart';

/// Model for personal information in resume
class ResumeData {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController birthPlaceController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  Uint8List? profileImageBytes;
  final List<ProfileLink> profileLinks = [];

  void dispose() {
    firstNameController.dispose();
    birthDateController.dispose();
    birthPlaceController.dispose();
    streetController.dispose();
    houseNumberController.dispose();
    postalCodeController.dispose();
    cityController.dispose();
    emailController.dispose();
    phoneController.dispose();
    for (final link in profileLinks) {
      link.dispose();
    }
  }

  String get fullName => firstNameController.text.trim();

  String get streetLine => [
        streetController.text.trim(),
        houseNumberController.text.trim(),
      ].where((s) => s.isNotEmpty).join(' ');

  String get cityLine => [
        postalCodeController.text.trim(),
        cityController.text.trim(),
      ].where((s) => s.isNotEmpty).join(' ');
}
