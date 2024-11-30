class UIHelper {
  static UIHelper? _instance;
  int _mainColor = 0xffA96C12;

  UIHelper._();

  factory UIHelper.getInstance() {
    _instance ??= UIHelper._();
    return _instance!;
  }

  setMainColor(int color) {
    _mainColor = color;
  }

  int get mainColor => _mainColor;
}
