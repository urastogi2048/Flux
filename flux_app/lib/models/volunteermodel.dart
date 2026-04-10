import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerModel {
  String uid;

  List<String> skills;
  List<String> availability; 

  GeoPoint location;

  int tasksCompleted;
  int tasksAccepted;
  int tasksRejected;

  double rating;

  List<String> assignedTaskIds;

  VolunteerModel({
    required this.uid,
    required this.skills,
    required this.availability,
    required this.location, 
    this.tasksCompleted = 0,
    this.tasksAccepted = 0,
    this.tasksRejected = 0,
    this.rating = 0.0,
    this.assignedTaskIds = const [],
  });
}