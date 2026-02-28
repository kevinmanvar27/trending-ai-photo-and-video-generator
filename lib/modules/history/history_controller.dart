import 'package:get/get.dart';

class HistoryItem {
  final String id;
  final String type;
  final String date;

  HistoryItem({
    required this.id,
    required this.type,
    required this.date,
  });
}

class HistoryController extends GetxController {
  final historyItems = <HistoryItem>[
    HistoryItem(
      id: '1',
      type: 'Image',
      date: '2026-02-27',
    ),
    HistoryItem(
      id: '2',
      type: 'Video',
      date: '2026-02-26',
    ),
    HistoryItem(
      id: '3',
      type: 'Image',
      date: '2026-02-25',
    ),
    HistoryItem(
      id: '4',
      type: 'Video',
      date: '2026-02-24',
    ),
  ].obs;

  void downloadAgain(String id) {
    Get.snackbar(
      'Success',
      'Downloading file again',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
