class TransferCallItem {
  String extension = '';
  String group = '';
  String id = '';

  TransferCallItem.fromJson(Map<String, dynamic> json) {
    id = json['name']?.toString() ?? "";
    extension = json['extension']?.toString() ?? "";
    group = json['group']?.toString() ?? "";
  }
}
