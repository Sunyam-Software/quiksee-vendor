import 'package:quiksee_vendor_app/data/model/image_full_url.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';

class ReviewModel {
  int? id;
  int? productId;
  int? customerId;
  int? orderId;
  String? comment;
  List<String>? attachment;
  double? rating;
  int? status;
  String? createdAt;
  String? updatedAt;
  Product? product;
  Customer? customer;
  Reply? reply;
  List<ImageFullUrl>? attachmentFullUrl;
  bool? isSaved;

  ReviewModel(
      {this.id,
        this.productId,
        this.customerId,
        this.orderId,
        this.comment,
        this.attachment,
        this.rating,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.customer,
        this.reply,
        this.attachmentFullUrl,
        this.isSaved});

  ReviewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    customerId = json['customer_id'];
    if(json['order_id'] != null){
      orderId = json['order_id'];
    }
    comment = json['comment'];
    if(json['attachment'] != null){
      try{

      }catch(e){

      }

    }

    rating = json['rating'].toDouble();
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    product = json['product'] != null ? Product.fromJson(json['product']) : null;
    customer = json['customer'] != null ?  Customer.fromJson(json['customer']) : null;
    reply = json['reply'] != null ?  Reply.fromJson(json['reply']) : null;
    if (json['attachment_full_url'] != null) {
      attachmentFullUrl = <ImageFullUrl>[];
      json['attachment_full_url'].forEach((v) {
        attachmentFullUrl!.add(ImageFullUrl.fromJson(v));
      });
    }
    isSaved = json['is_saved']??false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['customer_id'] = customerId;
    data['comment'] = comment;
    data['attachment'] = attachment;
    data['rating'] = rating;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (customer != null) {
      data['customer'] = customer!.toJson();
    }
    if (reply != null) {
      data['reply'] = reply!.toJson();
    }
    return data;
  }
}

class Reply {
  int? id;
  int? reviewId;
  String? addedBy;
  String? replyText;
  String? createdAt;
  String? updatedAt;

  Reply(
      {this.id,
        this.reviewId,
        this.addedBy,
        this.replyText,
        this.createdAt,
        this.updatedAt});

  Reply.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reviewId = json['review_id'];
    addedBy = json['added_by'];
    replyText = json['reply_text'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['review_id'] = reviewId;
    data['added_by'] = addedBy;
    data['reply_text'] = replyText;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
