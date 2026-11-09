import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/final_offer_rules.dart';
import '../../domain/repositories/dealer_offers_repository.dart';

/// Confirm the accepted price after inspecting the car, or lower it. A lower price needs a
/// reason, and a drop of more than 5% also needs evidence. The seller may decline for free.
class FinalOfferDialog extends StatefulWidget {
  final int accepted;
  const FinalOfferDialog({super.key, required this.accepted});

  static Future<FinalDraft?> show(BuildContext context, int accepted) =>
      showDialog<FinalDraft>(
        context: context,
        builder: (_) => FinalOfferDialog(accepted: accepted),
      );

  @override
  State<FinalOfferDialog> createState() => _FinalOfferDialogState();
}

class _FinalOfferDialogState extends State<FinalOfferDialog> {
  late final _price = TextEditingController(text: widget.accepted.toString());
  final _note = TextEditingController();
  final _evidence = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    _evidence.dispose();
    super.dispose();
  }

  int? get _priceValue => int.tryParse(_price.text.trim());

  List<String> get _links => [
    for (final line in _evidence.text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  bool get _lower => (_priceValue ?? widget.accepted) < widget.accepted;

  String? get _problem => FinalOfferRules.check(
    accepted: widget.accepted,
    price: _priceValue,
    reasonCode: _lower ? _reason : null,
    evidence: _links,
  );

  @override
  Widget build(BuildContext context) {
    final price = _priceValue;
    final drop = price == null
        ? 0.0
        : FinalOfferRules.dropPercent(widget.accepted, price);
    final problem = _problem;
    return AlertDialog(
      title: const Text('Final offer after inspection'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accepted price ${PriceFormatter.formatINR(widget.accepted)}. Keep it to confirm, or lower it if the car is not as described.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Final price (₹)',
                border: const OutlineInputBorder(),
                helperText: _lower
                    ? '${drop.toStringAsFixed(1)}% lower than accepted'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_lower) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Why is it lower?',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final e in finalReasonLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _reason = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _note,
                maxLength: 1000,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'What you found (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _evidence,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: drop > bigDropPercent
                      ? 'Evidence links (required)'
                      : 'Evidence links (optional)',
                  helperText:
                      'One link per line: photos or an inspection report',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (problem != null && price != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  problem,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: problem != null
              ? null
              : () => Navigator.pop(
                  context,
                  FinalDraft(
                    price: price!,
                    reasonCode: _lower ? _reason : null,
                    reasonNote: _lower ? _note.text : null,
                    evidenceUrls: _lower ? _links : const [],
                  ),
                ),
          child: Text(_lower ? 'Send lower price' : 'Confirm price'),
        ),
      ],
    );
  }
}
