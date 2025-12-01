import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/grades_api_extensions.dart';
import '../utils/error_handler.dart';

/// Provider to manage monitoring notes (ghi chú theo dõi) for students.
///
/// This provider wraps the `ApiService` monitoring notes endpoints and
/// exposes convenient methods for fetching, creating, updating and
/// deleting notes. All API errors are captured and surfaced via
/// `errorMessage` and listeners are notified on state changes.
class MonitoringNotesProvider extends ChangeNotifier {
  /// Raw notes returned from the API.
  List<Map<String, dynamic>> notes = [];

  /// Currently selected note detail.
  Map<String, dynamic>? selectedNote;

  /// Loading and error state for the provider.
  bool isLoading = false;
  String? errorMessage;

  /// Category filter for client-side filtering. Values: all/academic/personal/attendance/other
  String categoryFilter = 'all';

  /// Currently loaded student id (if any)
  int? currentStudentId;

  /// Fetch a list of monitoring notes.
  ///
  /// Optionally filter by `studentId`, `semesterId` or `category` (api-level).
  /// On success, updates [notes] and [currentStudentId] when provided.
  Future<void> fetchNotes({int? studentId, int? semesterId, String? category}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await ApiService.instance.getMonitoringNotes(studentId: studentId, semesterId: semesterId, category: category);
      // The extension returns a Map with API-standard structure. Try to
      // extract an array under 'data' or fall back to the root map.
      final listData = resp['data'];
      if (listData is List) {
        notes = List<Map<String, dynamic>>.from(listData);
      } else {
        notes = [];
      }

      if (studentId != null) currentStudentId = studentId;
      errorMessage = null;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single note by id and set [selectedNote].
  Future<void> fetchNoteById(int noteId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await ApiService.instance.getMonitoringNoteById(noteId);
      final data = resp['data'] ?? resp;
      if (data is Map) selectedNote = Map<String, dynamic>.from(data);
      errorMessage = null;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch student timeline for monitoring notes and replace [notes].
  Future<void> fetchStudentTimeline(int studentId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await ApiService.instance.getStudentMonitoringTimeline(studentId);
      final listData = resp['data'];
      if (listData is List) {
        notes = List<Map<String, dynamic>>.from(listData);
      } else {
        notes = [];
      }

      currentStudentId = studentId;
      errorMessage = null;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new monitoring note and insert it into [notes].
  ///
  /// `userCode` is the student's user code. On success the created note
  /// from the API is prepended to the local list.
  Future<void> createNote({
    required String userCode,
    required int semesterId,
    required String category,
    required String title,
    required String content,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await ApiService.instance.createMonitoringNote(userCode: userCode, semesterId: semesterId, category: category, title: title, content: content);
      final created = resp['data'] ?? resp;
      if (created is Map) {
        notes.insert(0, Map<String, dynamic>.from(created));
      }

      // keep last success available; callers may read [errorMessage]==null to infer success
      errorMessage = null;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing note and mutate the local list.
  Future<void> updateNote({
    required int noteId,
    String? category,
    String? title,
    String? content,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await ApiService.instance.updateMonitoringNote(noteId: noteId, category: category, title: title, content: content);
      final updated = resp['data'] ?? resp;
      if (updated is Map) {
        final idx = notes.indexWhere((n) => (n['note_id'] ?? n['id']) == (updated['note_id'] ?? updated['id']));
        if (idx >= 0) {
          notes[idx] = Map<String, dynamic>.from(updated);
        }
      }

      errorMessage = null;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a note by id and remove it from [notes].
  Future<void> deleteNote(int noteId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiService.instance.deleteMonitoringNote(noteId);
      notes.removeWhere((n) => (n['note_id'] ?? n['id']) == noteId);
      errorMessage = null;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Set the client-side category filter for notes and notify listeners.
  void setCategoryFilter(String category) {
    categoryFilter = category;
    notifyListeners();
  }

  /// Fetch aggregated statistics for monitoring notes (returns raw api response)
  Future<Map<String, dynamic>?> fetchStatistics({int? semesterId}) async {
    try {
      final resp = await ApiService.instance.getMonitoringNotesStatistics(semesterId: semesterId);
      return resp;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ---------- Computed properties ----------

  /// Return notes filtered by [categoryFilter].
  List<Map<String, dynamic>> get filteredNotes {
    if (categoryFilter == 'all') return notes;
    return notes.where((n) => (n['category'] ?? '').toString().toLowerCase() == categoryFilter.toLowerCase()).toList();
  }

  /// Count notes by a given category.
  int getNoteCountByCategory(String category) {
    return notes.where((n) => (n['category'] ?? '').toString().toLowerCase() == category.toLowerCase()).length;
  }

  /// Map of category -> count for quick summaries.
  Map<String, int> get notesByCategory {
    final Map<String, int> m = {};
    for (final n in notes) {
      final c = (n['category'] ?? 'other').toString();
      m[c] = (m[c] ?? 0) + 1;
    }
    return m;
  }
}
