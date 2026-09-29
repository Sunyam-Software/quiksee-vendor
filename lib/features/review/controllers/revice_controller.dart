
import 'package:get/get.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/review/domain/models/review_model.dart';
import 'package:quiksee/features/review/domain/services/review_service_interface.dart';

class ReviewController extends GetxController implements GetxService {

  final ReviewServiceInterface reviewServiceInterface;
  ReviewController({required this.reviewServiceInterface});
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final List<String> _reviewTypeList = [ 'regular', 'saved'];
  List<String> get reviewTypeList => _reviewTypeList;
  String _selectedReviewType = 'regular';
  String get selectedReviewType=>_selectedReviewType;

  ReviewModel? _reviewModel;
  ReviewModel? get reviewModel => _reviewModel;


  Future<void> getReviewList(int offset, {bool reload = true}) async {
    _isLoading = true;
    update();
    if(reload){
      _reviewModel?.review = [];
    }
    Response response = await reviewServiceInterface.getReviewList(offset, _selectedReviewType == 'regular' ? 0 : 1);
    if (response.statusCode == 200) {
      if(offset == 1){
        _reviewModel = ReviewModel.fromJson(response.body);
      }else{
        _reviewModel!.totalSize = ReviewModel.fromJson(response.body).totalSize;
        _reviewModel!.offset = ReviewModel.fromJson(response.body).offset;
        _reviewModel!.review!.addAll(ReviewModel.fromJson(response.body).review!);
      }
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }


  Future<void> savedReview( int? reviewId, int isSaved, int? index) async {
    ResponseModel responseModel = await reviewServiceInterface.saveReview(reviewId, isSaved);
    if(responseModel.isSuccess){
      _reviewModel!.review![index!].isSaved = _reviewModel!.review![index].isSaved == 1 ? 0 : 1;
    }
    update();
  }

  set setSelectedReviewType(String type) {
    _selectedReviewType = type;
  }

}