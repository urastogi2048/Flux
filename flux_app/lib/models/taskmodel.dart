import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel{
  String taskid;
  String ngoid;
  String title;
  String description;
  List<GeoPoint> locations;
  String deadline;
  List<String> requiredvolunteeruid;
TaskModel({
  required this.taskid,
  required this.ngoid,
  required this.title,
  required this.description,
  required this.locations,
  required this.deadline,
  required this.requiredvolunteeruid,
});

}