import 'package:cloud_firestore/cloud_firestore.dart';

class NGOmodel {
  String ngoid;
  String name;

  String description;
  List<GeoPoint> servicelocations;
  String adminid;//later multiple admins ka sochenge
  NGOmodel({
    required this.ngoid,
    required this.name,
    required this.description,
    required this.servicelocations,
    required this.adminid,
  });



}