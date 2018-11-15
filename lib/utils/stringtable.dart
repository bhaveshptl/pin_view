StringTable strings = new StringTable();

class StringTable {
  StringTable._internal();
  factory StringTable() => StringTable._internal();

  static Map<String, dynamic> _table;
  int language;
  String rupee = "₹";
  String chips = "images/chips.png";

  String get(String title) {
    return _table[title] == null ? "" : _table[title];
  }

  set({int language, Map<String, dynamic> table}) {
    this.language = language;
    StringTable._table = table;
  }
}
