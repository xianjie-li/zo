import "dart:collection";

import "package:flutter/widgets.dart";

/// 管理值的选中状态
///
/// 泛型说明:
/// - Val 选中值的类型
/// - Opt 选项的类型, 在很多场景中 Val = Opt
///
/// 所有参与选中的值必须能正确支持 hashCode 和 == 操作符进行对比
///
/// unlisted options: 对于不在待选选项清单中的选项, 称为未列出选项,
/// 用户可以通过 [getSelectionState] 来获取这些未列出的选项
///
/// 为了让数据选项的获取方式对用户更可控，很多方法都提供了 allOptions 参数，
/// 这避免 [Selector] 内部对选项信息的直接声明
class Selector<Val, Opt> extends ChangeNotifier {
  Selector({
    Iterable<Val>? selected,
    this.valueGetter,
  }) : _selected = selected?.toSet() ?? {};

  /// 控制如何从 [Opt] 中获取选中值, 如果选项本身就代表值则不需要设置
  Val Function(Opt)? valueGetter;

  /// 已选中选项
  /// 选中值不一定存在于选项列表中
  final Set<Val> _selected;

  /// 获取指定选项对应的值
  Val getOptionValue(Opt opt) {
    return valueGetter == null ? opt as Val : valueGetter!(opt);
  }

  /// 将指定的选项转换为值
  Set<Val> getOptionsValues(Iterable<Opt> options) {
    return options.map(getOptionValue).toSet();
  }

  /// 指定的值是否选中
  bool isSelected(Val value) {
    return _selected.contains(value);
  }

  /// 是否有被选中的值
  bool hasSelected() {
    return _selected.isNotEmpty;
  }

  /// 是否部分选中, 需要传入当前所有选项
  bool isPartialSelected(Iterable<Opt> allOptions) {
    if (_selected.isEmpty || _selected.length == allOptions.length) {
      return false;
    }

    for (var opt in allOptions) {
      if (!_selected.contains(getOptionValue(opt))) {
        return true;
      }
    }

    return false;
  }

  /// 是否选中了所有值, 需要传入当前所有选项
  bool isAllSelected(Iterable<Opt> allOptions) {
    if (_selected.length < allOptions.length) return false;

    for (var opt in allOptions) {
      if (!_selected.contains(getOptionValue(opt))) {
        return false;
      }
    }

    return true;
  }

  /// 获取当前选中值
  Set<Val> getSelected() {
    return _selected;
  }

  /// 获取当前选中值, 相比 [getSelected] 它包含更完整的信息, 比如不存在于列表中的选项,
  /// 选项值和选项列表等
  SelectorState<Val, Opt> getSelectionState(Iterable<Opt> allOptions) {
    final selected = <Val>{};
    final selectedOptions = <Opt>{};
    final unlistedSelected = <Val>{};

    final HashMap<Val, Opt> optionsMap = HashMap();

    for (final option in allOptions) {
      optionsMap[getOptionValue(option)] = option;
    }

    for (final option in _selected) {
      final opt = optionsMap[option];

      if (opt != null) {
        selected.add(option);
        selectedOptions.add(opt);
      } else {
        unlistedSelected.add(option);
      }
    }

    return SelectorState(
      selected: selected,
      selectedOptions: selectedOptions,
      unlistedSelected: unlistedSelected,
    );
  }

  /// 选中
  void select(Val value) {
    _selected.add(value);

    notifyListeners();
  }

  /// 取消选中
  void unselect(Val value) {
    _selected.remove(value);

    notifyListeners();
  }

  /// 批量选中指定列表的值
  void selectList(Iterable<Val> values) {
    _selected.addAll(values);

    notifyListeners();
  }

  /// 取消选中指定列表的值
  void unselectList(Iterable<Val> values) {
    _selected.removeAll(values);

    notifyListeners();
  }

  /// 选中所有值, 需要传入当前所有选项
  void selectAll(Iterable<Opt> allOptions) {
    if (valueGetter != null) {
      _selected.addAll(allOptions.map(valueGetter!));
    } else {
      _selected.addAll(allOptions as Iterable<Val>);
    }

    notifyListeners();
  }

  /// 取消选中所有值
  void unselectAll() {
    _selected.clear();

    notifyListeners();
  }

  /// 反选指定值
  void toggle(Val value) {
    if (_selected.contains(value)) {
      _selected.remove(value);
    } else {
      _selected.add(value);
    }

    notifyListeners();
  }

  /// 反选所有值, 需要传入当前所有选项
  void toggleAll(Iterable<Opt> allOptions) {
    for (var opt in allOptions) {
      final value = getOptionValue(opt);

      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    }

    notifyListeners();
  }

  /// 设置当前选中值为指定的值
  void setSelected(Iterable<Val> values) {
    _selected.clear();
    _selected.addAll(values);

    notifyListeners();
  }

  @override
  void dispose() {
    _selected.clear();
    super.dispose();
  }
}

/// 包含了额外信息的选中状态
class SelectorState<Val, Opt> {
  SelectorState({
    required this.selected,
    required this.selectedOptions,
    required this.unlistedSelected,
  });

  /// 所有在选项清单中的值
  final Set<Val> selected;

  /// [selected] 对应的选项信息
  final Set<Opt> selectedOptions;

  /// 未在选项清单的所有选中值
  final Set<Val> unlistedSelected;
}
