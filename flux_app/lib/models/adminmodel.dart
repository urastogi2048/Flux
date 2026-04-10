import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel{
  String uid;
  String ngoname;
  String ngotype;
  List<GeoPoint> servicelocations;
  int totalTasksCreated;
  int activeTasks;

  List<String> managedTaskIds;
  AdminModel({
    required this.uid,
    required this.ngoname,
    required this.ngotype,
    required this.servicelocations,
    this.totalTasksCreated = 0,
    this.activeTasks=0,
    this.managedTaskIds = const [],

  });
  
}