/// Normalizes task data from Firestore to ensure compatibility
/// Handles both manually-created tasks and ML-generated tasks
class TaskNormalizer {
  /// Normalizes a single task document
  static Map<String, dynamic> normalizeTask(
    Map<String, dynamic> data, {
    required String taskId,
    String? ngoidFallback,
  }) {
    // Ensure document ID is included
    data['taskid'] = taskId;

    // Convert status from 'active' to 'ASSIGNED' for backward compatibility
    if (data['status'] == 'active') {
      data['status'] = 'ASSIGNED';
    }

    // Ensure status field exists and is uppercase
    data['status'] = (data['status']?.toString() ?? 'ASSIGNED').toUpperCase();

    // Handle ML-generated tasks with nested structure
    // Extract volunteers from required_resources
    if (data['required_resources'] != null && data['maxvolunteers'] == null) {
      final volunteers = data['required_resources']['volunteers'];
      if (volunteers != null) {
        data['maxvolunteers'] = volunteers;
      }
    }

    // Map 'objective' to 'description' if description is missing
    if ((data['description'] == null || data['description'] == '') &&
        data['objective'] != null) {
      data['description'] = data['objective'];
    }

    // Map 'timeline.deadline' to 'deadline' if deadline is missing or is a nested object
    if (data['timeline'] != null) {
      final timelineDeadline = data['timeline']['deadline'];
      if (timelineDeadline != null) {
        data['deadline'] = timelineDeadline;
      }
    }
    
    // If deadline is still an object/map, convert to string representation
    if (data['deadline'] is Map) {
      final deadlineMap = data['deadline'] as Map;
      data['deadline'] = deadlineMap['deadline'] ?? deadlineMap.toString();
    }

    // Ensure ngoid is set (critical for filtering)
    if (data['ngoid'] == null && ngoidFallback != null) {
      data['ngoid'] = ngoidFallback;
    }

    // Ensure title exists
    data['title'] ??= 'Untitled Task';

    // Ensure description exists
    data['description'] ??= 'No description provided';

    // Log task normalization for debugging
    print('[TaskNormalizer] Task ${data['taskid']} normalized: '
        'status=${data['status']}, '
        'ngoid=${data['ngoid']}, '
        'title=${data['title']}');

    return data;
  }

  /// Validates that a task has all required fields for rendering
  static bool isTaskValid(Map<String, dynamic> task) {
    final requiredFields = ['taskid', 'status', 'ngoid', 'title'];
    for (final field in requiredFields) {
      if (task[field] == null || task[field].toString().isEmpty) {
        print('[TaskNormalizer] Invalid task: missing field "$field"');
        return false;
      }
    }
    return true;
  }

  /// Gets a human-readable error message for debugging
  static String getTaskDebugInfo(Map<String, dynamic> task) {
    final descStr = (task['description'] ?? 'MISSING').toString();
    final descPreview = descStr.length > 50 ? descStr.substring(0, 50) + '...' : descStr;
    
    return '''
Task Debug Info:
  ID: ${task['taskid'] ?? 'MISSING'}
  Title: ${task['title'] ?? 'MISSING'}
  Status: ${task['status'] ?? 'MISSING'}
  NGO ID: ${task['ngoid'] ?? 'MISSING'}
  Description: $descPreview
  Max Volunteers: ${task['maxvolunteers'] ?? 'NOT SET'}
  Deadline: ${task['deadline'] ?? 'NOT SET'}
    ''';
  }
}
