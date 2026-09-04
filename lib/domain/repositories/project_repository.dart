import '../models/project.dart';

abstract class ProjectRepository {
  Future<Project?> getById(String id, {bool includeDeleted = false});

  Future<List<Project>> list({bool includeDeleted = false});

  Future<Project> save(Project project);

  Future<void> softDelete(String id, {required DateTime deletedAt});

  Stream<List<Project>> watchAll({bool includeDeleted = false});
}
