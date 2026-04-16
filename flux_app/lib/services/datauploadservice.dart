import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DataUploadService {
  final baseUrl = "https://flux-test-cg9c.onrender.com";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Map<String,dynamic>?> getUploadUrl ({
    required String userId,
    required String ngoId,
    required String fileType,
  }) async {
     try {
      final body ={
        'user_id':userId,
        'ngo_id': ngoId,
        'file_type': fileType,
      };
      final res= await http.post(
        Uri.parse('$baseUrl/get_upload_url'),
        headers: {'Content-Type': 'application/json'},
        body:jsonEncode(body),
      );
      if (res.statusCode == 200) {
      
      final Map<String, dynamic> data = jsonDecode(res.body);
      
      return data;
      
    } else {
      print('Error: ${res.statusCode} - ${res.body}');
      return null;
    }

     }
     catch(e) {
      return null;
     }
  }
  Future<bool?> uploadFiletoS3({required String signedUrl, required File file, required String fileType,}) async {
    try{
      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes');
      print('Signed URL: $signedUrl');
      print('File Type: $fileType');
      
      final res = await http.put(
        Uri.parse(signedUrl),
        body: bytes,
        headers: {
          "Content-Type": fileType,
          "x-amz-server-side-encryption": "AES256",
        }
      );
      
      print('S3 Upload Status: ${res.statusCode}');
      print('S3 Response Body: ${res.body}');
      print('S3 Response Headers: ${res.headers}');
      
      if(res.statusCode == 200 || res.statusCode==204 ){
        return true; 
      }else {
        print('S3 Upload Failed with status ${res.statusCode}');
        return false;

      }
    }
    catch(e) {
      print('Exception in uploadFiletoS3: $e');
      return null;
    }
  }
  Future <bool?> saveMetaData ({required String userId, required String ngoId, required String key, required String fileUrl,})async {
    try {
      final body= {
        'ngo_id':ngoId,
        'user_id':userId,
        'key':key,
        'file_url':fileUrl,
      };
      
      print('===== SAVE METADATA DEBUG =====');
      print('Endpoint: $baseUrl/save-metadata');
      print('Body: $body');
      print('================================');
      
      final res= await http.post (
        Uri.parse('$baseUrl/save-metadata'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      print('Save Metadata Status: ${res.statusCode}');
      print('Save Metadata Response: ${res.body}');
      print('Save Metadata Headers: ${res.headers}');
      
      if(res.statusCode==200 || res.statusCode==204) {
        return true;
      } else {
        print('Save Metadata Failed with status ${res.statusCode}');
        return false;
      }
    }catch(e) {
      print('Exception in saveMetaData: $e');
      return null;
    }
  }
  Future<List<Map<String,dynamic>>?>getNGODocs ({required String ngoId,}) async {
    try{
      final res= await http.get(
        Uri.parse('$baseUrl/uploads/ngo/$ngoId'),
        headers: {
          "ContentType": 'application/json'
        },

      );
      if(res.statusCode==200) {
        final data = jsonDecode(res.body);
        if(data is List) {
          return List<Map<String,dynamic>>.from(data);

        }else {
          return null;
        }
      }
    }catch(e) {
      return null;
    }
  }
}