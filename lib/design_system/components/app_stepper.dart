import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';

final class AppStepper extends StatefulWidget {
  const AppStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum,
    this.maximum,
    this.errorText,
    this.enabled = true,
    this.editable = true,
    super.key,
  });

  final String label;
  final String value;
  final int? minimum;
  final int? maximum;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final bool editable;

  @override
  State<AppStepper> createState() => _AppStepperState();
}

final class _AppStepperState extends State<AppStepper> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(AppStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final current = int.tryParse(_controller.text);
    if (current == null) return;
    final next = current + delta;
    if (widget.minimum != null && next < widget.minimum!) return;
    if (widget.maximum != null && next > widget.maximum!) return;
    widget.onChanged(next.toString());
  }

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(widget.value);
    return Semantics(
      label: widget.label,
      value: widget.value,
      increasedValue: current == null ? null : '${current + 1}',
      decreasedValue: current == null ? null : '${current - 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.minimum != null && widget.maximum != null)
                Text('范围：${widget.minimum}～${widget.maximum}'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconButton.outlined(
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.minimumTapTarget,
                  height: AppSizes.minimumTapTarget,
                ),
                tooltip: '减少${widget.label}',
                onPressed:
                    widget.enabled &&
                        current != null &&
                        (widget.minimum == null || current > widget.minimum!)
                    ? () => _step(-1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: widget.editable
                    ? TextField(
                        controller: _controller,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                        ],
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: widget.label,
                          errorText: widget.errorText,
                        ),
                        onChanged: widget.onChanged,
                      )
                    : InputDecorator(
                        isEmpty: false,
                        decoration: InputDecoration(
                          labelText: widget.label,
                          errorText: widget.errorText,
                        ),
                        child: Center(
                          child: Text(
                            widget.value,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.minimumTapTarget,
                  height: AppSizes.minimumTapTarget,
                ),
                tooltip: '增加${widget.label}',
                onPressed:
                    widget.enabled &&
                        current != null &&
                        (widget.maximum == null || current < widget.maximum!)
                    ? () => _step(1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
