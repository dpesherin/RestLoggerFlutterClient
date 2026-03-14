import '../models/api_documentation_project.dart';
import '../services/storage_service.dart';

class ApiDocsRepository {
  const ApiDocsRepository();

  Future<List<ApiDocumentationProject>> loadProjects() {
    return StorageService.getApiDocumentationProjects();
  }

  Future<void> saveProjects(List<ApiDocumentationProject> projects) {
    return StorageService.saveApiDocumentationProjects(projects);
  }
}
