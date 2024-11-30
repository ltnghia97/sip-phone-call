import 'package:flutter/material.dart';

extension LocaleTranslate on Locale {
  String translate(String rawText) {
    String enString = '';
    String viString = '';
    switch (rawText) {
      case 'Connecting':
        enString = 'Connecting';
        viString = 'Đang kết nối';
        break;
      case 'Ringing':
        enString = 'Ringing';
        viString = 'Đang đổ chuông';
        break;
      case 'Callee is busy':
        enString = 'Callee is busy';
        viString = 'Người nhận bận';
        break;
      case 'Call is declined':
        enString = 'Call is declined';
        viString = 'Người nhận từ chối';
        break;
      case 'Call ended':
        enString = 'Call ended';
        viString = 'Cuộc gọi kết thúc';
        break;
      case 'Calling':
        enString = 'Calling';
        viString = 'Đang gọi';
        break;
      case "Send":
        enString = 'Send';
        viString = 'Gửi';
        break;
      case "Cancel":
        enString = 'Cancel';
        viString = 'Huỷ';
        break;
      case "titleTransferCall":
        enString = 'Transfer the call';
        viString = 'Chuyển cuộc gọi';
        break;
      case "hintSearchTransferCall":
        enString = 'Input group name or ext';
        viString = 'Nhập tên nhóm hoặc ext';
        break;
      case "transferCallSuccessfully":
        enString = 'Transfer the call successfully';
        viString = 'Chuyển cuộc gọi thành công';
        break;
      case "transferCallFailed":
        enString = 'Transfer the call failed';
        viString = 'Chuyển cuộc gọi không thành công';
        break;
      case "transferTargetReject":
        enString = 'Transfer target rejected the call';
        viString = 'Người nhận từ chối cuộc gọi';
        break;
      case "transferringTo":
        enString = 'Transferring the call to';
        viString = 'Đang chuyển cuộc gọi tới';
        break;
      case "Close":
        enString = 'Close';
        viString = 'Đóng';
        break;
      case "callingTo":
        enString = 'Calling to';
        viString = 'Đang gọi tới';
        break;
      case "transferredTo":
        enString = 'Transferred to';
        viString = 'Đã gọi tới';
        break;
      case "cancelCallToTarget":
        enString = "Cancelled the call to transfer target";
        viString = "Đã huỷ cuộc gọi tới người nhận";
        break;
      case "Attended":
        enString = "Attended";
        viString = "Attended";
        break;
      case "Blind":
        enString = "Blind";
        viString = "Blind";
        break;
      case "Holding":
        enString = "Holding";
        viString = "Đang giữ máy";
        break;
      case "messageHolding":
        enString = "Holding";
        viString = "Đang chờ chuyển tiếp";
        break;
    }

    return languageCode == 'vi' ? viString : enString;
  }
}
