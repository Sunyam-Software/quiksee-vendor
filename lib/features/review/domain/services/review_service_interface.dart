

abstract class ReviewServiceInterface{
  Future<dynamic> getReviewList(int offset, int isSaved);
  Future<dynamic> saveReview( int? reviewId, int isSaved);
}