class NotificationBody {
  String? type;
  int? orderId;
  int? refundId;
  int? orderDetailsId;
  String? messageKey;

  NotificationBody({
    this.type,
    this.orderId,
    this.refundId,
    this.orderDetailsId,
    this.messageKey,
  });

  factory NotificationBody.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return NotificationBody(
      type: json['type']?.toString(),
      orderId: parseInt(json['order_id']),
      refundId: parseInt(json['refund_id']),
      orderDetailsId: parseInt(json['order_details_id']),
      messageKey: json['message_key']?.toString() ?? json['title']?.toString(),
    );
  }
}
