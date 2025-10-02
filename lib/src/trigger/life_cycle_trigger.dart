import "package:flutter/widgets.dart";

/// 在 Stateful 组件生命周期的各个阶段进行通知
class LifeCycleTrigger extends StatefulWidget {
  const LifeCycleTrigger({
    super.key,
    this.child,
    this.initState,
    this.didUpdateWidget,
    this.dispose,
    this.didChangeDependencies,
    this.activate,
    this.deactivate,
  });

  final Widget? child;

  final void Function()? initState;

  final void Function()? didUpdateWidget;

  final void Function()? dispose;

  final void Function()? didChangeDependencies;

  final void Function()? activate;

  final void Function()? deactivate;

  @override
  State<LifeCycleTrigger> createState() => _LifeCycleTriggerState();
}

class _LifeCycleTriggerState extends State<LifeCycleTrigger> {
  @override
  void initState() {
    super.initState();
    widget.initState?.call();
  }

  @override
  void didUpdateWidget(covariant LifeCycleTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.didUpdateWidget?.call();
  }

  @override
  void dispose() {
    super.dispose();
    widget.dispose?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call();
  }

  @override
  void activate() {
    super.activate();
    widget.activate?.call();
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.deactivate?.call();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
