import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';

class PaginatedListViewWidget extends StatefulWidget {
  final ScrollController? scrollController;
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? offset;
  final Widget itemView;
  final bool enabledPagination;
  final bool reverse;

  final int limit;
  const PaginatedListViewWidget({
    super.key, required this.scrollController, required this.onPaginate, required this.totalSize,
    required this.offset, required this.itemView, this.enabledPagination = true, this.reverse = false,
    this.limit = 10,
  });

  @override
  State<PaginatedListViewWidget> createState() => _PaginatedListViewWidgetState();
}

class _PaginatedListViewWidgetState extends State<PaginatedListViewWidget> {
  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _offset = 1;
    _offsetList = [1];

    widget.scrollController?.addListener(() {
      if (!widget.scrollController!.hasClients) return;
      final position = widget.scrollController!.position;

      final nearEnd = position.pixels >= (position.maxScrollExtent - 240);
      if (nearEnd
          && widget.totalSize != null && !_isLoading && widget.enabledPagination) {
        if(mounted) {
          _paginate();
        }
      }
    });
  }

  void _paginate() async {
    final int pageLimit = widget.limit <= 0 ? 10 : widget.limit;
    int pageSize = (widget.totalSize! / pageLimit).ceil();
    if (_offset! < pageSize && !_offsetList.contains(_offset!+1)) {

      setState(() {
        _offset = _offset! + 1;
        _offsetList.add(_offset);
        _isLoading = true;
      });
      await widget.onPaginate(_offset);
      setState(() {
        _isLoading = false;
      });
    }else {
      if(_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if(widget.offset != null) {
      _offset = widget.offset;
      _offsetList = [];
      for(int index=1; index<=widget.offset!; index++) {
        _offsetList.add(index);
      }
    }

    final int pageLimit = widget.limit <= 0 ? 10 : widget.limit;
    final int pageSize = widget.totalSize == null
        ? 0
        : (widget.totalSize! / pageLimit).ceil();

    return Column(children: [
      widget.reverse ? const SizedBox() : widget.itemView,

       widget.totalSize == null || _offset! >= pageSize || _offsetList.contains(_offset!+1) ? const SizedBox() : Center(child: Padding(
        padding: (_isLoading ) ?  const EdgeInsets.all(Dimensions.paddingSizeSmall) : EdgeInsets.zero,
        child: _isLoading ? const CircularProgressIndicator() : const SizedBox(),
      )),

      widget.reverse ? widget.itemView : const SizedBox(),

    ]);
  }
}
