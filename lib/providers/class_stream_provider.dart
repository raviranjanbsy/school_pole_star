import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'dart:developer' as developer;

part 'class_stream_provider.g.dart';

@riverpod
Stream<List<StreamItem>> announcements(AnnouncementsRef ref, String classId) {
  final authService = ref.watch(authServiceProvider);
  // This correctly listens to the combined stream and filters for announcements.
  return authService.getStreamForClass(classId).map((items) {
    developer.log(
      'Announcements Provider: Received ${items.length} total items. Filtering for "announcement".',
      name: 'class_stream_provider',
    );
    for (final item in items) {
      developer.log('Item type: "${item.type}", title: ${item.title}',
          name: 'class_stream_provider');
    }
    return items.where((i) => i.type == 'announcement').toList();
  });
}

@riverpod
Stream<List<StreamItem>> assignments(AssignmentsRef ref, String classId) {
  final authService = ref.watch(authServiceProvider);
  // This correctly listens to the combined stream and filters for assignments.
  return authService.getStreamForClass(classId).map((items) {
    developer.log(
      'Assignments Provider: Received ${items.length} total items. Filtering for "assignment".',
      name: 'class_stream_provider',
    );
    for (final item in items) {
      developer.log('Item type: "${item.type}", title: ${item.title}',
          name: 'class_stream_provider');
    }
    return items.where((i) => i.type == 'assignment').toList();
  });
}
