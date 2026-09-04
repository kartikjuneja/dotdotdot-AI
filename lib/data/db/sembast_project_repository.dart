import 'package:sembast/sembast.dart';

import '../../domain/models/project.dart';
import '../../domain/repositories/project_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastProjectRepository implements ProjectRepository {
  SembastProjectRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.projects);

  @override
  Future<Project?> getById(String id, {bool includeDeleted = false}) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    final project = Project.fromJson(mapFromRecord(snap));
    if (!includeDeleted && project.isDeleted) return null;
    return project;
  }

  @override
  Future<List<Project>> list({bool includeDeleted = false}) async {
    final finder = softDeleteAwareFinder(
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('updatedAt', false)],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => Project.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<Project> save(Project project) async {
    await _store.record(project.id).put(_db, mapForPut(project.toJson()));
    return project;
  }

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {
    final existing = await getById(id, includeDeleted: true);
    if (existing == null) return;
    await save(
      existing.copyWith(
        deletedAt: deletedAt,
        updatedAt: deletedAt,
      ),
    );
  }

  @override
  Stream<List<Project>> watchAll({bool includeDeleted = false}) {
    final finder = softDeleteAwareFinder(
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('updatedAt', false)],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) =>
              rows.map((s) => Project.fromJson(mapFromRecord(s))).toList(),
        );
  }
}
