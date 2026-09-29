import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/common/basewidgets/paginated_list_view_widget.dart';
import 'package:quiksee/features/chat/domain/models/message_model.dart';
import 'package:quiksee/features/chat/widgets/message_bubble_widget.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class MessageListViewWidget extends StatelessWidget {
  final ScrollController scrollController;
  final int? userId;
  const MessageListViewWidget({super.key, required this.scrollController, this.userId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (chatController) {
        return SingleChildScrollView(
          controller: scrollController,
          reverse: true,
          child: PaginatedListViewWidget(
            reverse: true,
            scrollController: scrollController,
            totalSize: chatController.messageModel?.totalSize,
            offset: chatController.messageModel?.offset,
            onPaginate: (int? offset) async => await chatController.getChats(offset!, userId),
            limit: chatController.messageModel?.limit ?? 25,

            itemView: ListView.builder(
              itemCount: chatController.messageModel?.message?.length,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              reverse: true,
              itemBuilder: (context, index) {

                return Column(
                  crossAxisAlignment: chatController.messageModel?.message?[index].sentByDeliveryMan ?? false ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [

                    if(_willShowDate(index, chatController.messageModel) != null) Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeExtraSmall,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        child: Text(
                          DateConverter.dateStringMonthYear(DateTime.tryParse(chatController.messageModel!.message![index].createdAt!)),
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha:0.5),
                          ), textDirection: TextDirection.ltr,
                        ),
                      ),
                    ),

                    MessageBubbleWidget(
                      message: chatController.messageModel!.message![index],
                      previous: (index != 0) ? chatController.messageModel!.message![index -1 ] : null,
                      next: index == (chatController.messageModel!.message!.length -1) ?  null : chatController.messageModel!.message![index + 1],
                    ),
                  ],
                );
              },

            ),
          ),
        );
      }
    );
  }

  String? _willShowDate(int index, MessageModel? messageModel) {

    if(messageModel?.message == null) return null;

    final Message currentMessage = messageModel!.message![index];
    final nextMessage = index < ((messageModel.message?.length ?? 0) - 1) ? messageModel.message![index + 1] : null;

    DateTime? _currentMessageDate = currentMessage.createdAt == null ? null : DateTime.tryParse(currentMessage.createdAt!);
    DateTime? _nextMessageDate = nextMessage?.createdAt == null ? null : DateTime.tryParse(nextMessage!.createdAt!);
    bool _isFirst = index == ((messageModel.message?.length ?? 0) - 1);

    if (_isFirst || (_nextMessageDate?.day != _currentMessageDate?.day)) {
      return DateConverter.dateStringMonthYear(_currentMessageDate);
    }
    return null;
  }

}
