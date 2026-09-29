import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/review/domain/repositories/review_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class ReviewRepository implements ReviewRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  ReviewRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> getReviewList(int offset, int isSaved) async {
    return await apiClient.getData('${AppConstants.reviewListUri}?is_saved=$isSaved&limit=20&offset=$offset');
  }

  @override
  Future<Response> saveReview( int? reviewId, int isSaved) async {
    Response _response = await apiClient.postData(AppConstants.addToSavedReviewList,
      {
        'review_id': reviewId,
        '_method': "put",
        'is_saved': isSaved
      });
    return _response;
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList() {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}