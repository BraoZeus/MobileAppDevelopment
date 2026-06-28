import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  bool _scrollToExams = false;
  bool _scrollToTop = false;

  int get selectedIndex => _selectedIndex;
  bool get scrollToExams => _scrollToExams;
  bool get scrollToTop => _scrollToTop;

  void setTab(int index, {bool scrollToExams = false, bool scrollToTop = false}) {
    _selectedIndex = index;
    _scrollToExams = scrollToExams;
    _scrollToTop = scrollToTop;
    notifyListeners();
  }

  void consumeScrollToExams() {
    _scrollToExams = false;
  }

  void consumeScrollToTop() {
    _scrollToTop = false;
  }
}
