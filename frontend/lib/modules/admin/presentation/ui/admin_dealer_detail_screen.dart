import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dealer/domain/entities/dealer_application.dart';
import '../../domain/repositories/admin_dealer_review_repository.dart';
import '../providers/admin_dealer_review_providers.dart';
import 'admin_dealer_verification_screen.dart' show statusStyle;

/// One dealer application: details, per-document review, and the decision buttons.
class AdminDealerDetailScreen extends ConsumerStatefulWidget {
  final String dealerId;
  const AdminDealerDetailScreen({super.key, required this.dealerId});

  @override
  ConsumerState<AdminDealerDetailScreen> createState() =>
      _AdminDealerDetailScreenState();
}

class _AdminDealerDetailScreenState
    extends ConsumerState<AdminDealerDetailScreen> {
  bool _busy = false;

  AdminDealerReviewRepository get _repo =>
      ref.read(adminDealerReviewRepositoryProvider);

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : null,
        ),
      );
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminDealerDetailProvider(widget.dealerId));
      ref.invalidate(adminDealerListProvider);
      if (success != null && mounted) _toast(success);
    } catch (e) {
      if (mounted) _toast(apiErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for a written reason; returns null if cancelled.
  Future<String?> _askReason(
    String title,
    String hint, {
    bool required = true,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(hintText: hint, errorText: error),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (required && text.length < 3) {
                    setLocal(() => error = 'Please write at least a few words');
                    return;
                  }
                  Navigator.pop(context, text);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _decide(
    String title,
    String hint,
    Future<void> Function(String reason) action,
    String done,
  ) async {
    final reason = await _askReason(title, hint);
    if (reason == null) return;
    await _run(() => action(reason), success: done);
  }

  Future<void> _viewDocument(DealerDocument doc) async {
    try {
      final file = await _repo.documentFile(widget.dealerId, doc.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    doc.type?.label ?? doc.originalName,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: file.isImage && file.bytes.isNotEmpty
                        ? InteractiveViewer(
                            child: Image.memory(
                              file.bytes,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Text(
                              'PDF files cannot be previewed here yet (${doc.originalName}).',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) _toast(apiErrorMessage(e), error: true);
    }
  }

  Future<void> _rejectDocument(DealerDocument doc) async {
    final note = await _askReason(
      'Reject ${doc.type?.label ?? 'document'}',
      'Tell the dealer what is wrong',
    );
    if (note == null) return;
    await _run(
      () => _repo.reviewDocument(
        widget.dealerId,
        doc.id,
        accept: false,
        note: note,
      ),
      success: 'Document rejected',
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(adminDealerDetailProvider(widget.dealerId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dealer application')),
      body: app.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiErrorMessage(e)),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(adminDealerDetailProvider(widget.dealerId)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(DealerApplication app) {
    final (label, color, bg) = statusStyle(app.status);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.businessName,
                              style: AppTextStyles.headlineMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _fact('City', app.city),
                      _fact('Address', app.address ?? 'Not provided'),
                      _fact(
                        'GSTIN',
                        (app.gstin ?? '').isEmpty ? 'Not provided' : app.gstin!,
                      ),
                      if (app.statusReason != null)
                        _fact('Last decision note', app.statusReason!),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documents', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      if (app.documents.isEmpty)
                        Text(
                          'No documents uploaded.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      for (final doc in app.documents) _documentRow(app, doc),
                      if (app.missingDocuments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            'Missing: ${app.missingDocuments.join(', ')}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ..._decisions(app),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    border: Border.all(color: AppColors.border),
  );

  Widget _fact(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(name, style: AppTextStyles.bodySmall)),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _documentRow(DealerApplication app, DealerDocument doc) {
    final (String text, Color color) = switch (doc.status) {
      DocumentStatus.pending => ('Awaiting review', AppColors.info),
      DocumentStatus.accepted => ('Accepted', AppColors.success),
      DocumentStatus.rejected => ('Rejected', AppColors.error),
    };
    final canReview = app.status == DealerStatus.pending && !_busy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.type?.label ?? doc.originalName,
            style: AppTextStyles.labelLarge,
          ),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
          if (doc.reviewNote != null)
            Text(doc.reviewNote!, style: AppTextStyles.bodySmall),
          Wrap(
            children: [
              TextButton(
                onPressed: () => _viewDocument(doc),
                child: const Text('View'),
              ),
              if (canReview) ...[
                TextButton(
                  onPressed: doc.status == DocumentStatus.accepted
                      ? null
                      : () => _run(
                          () => _repo.reviewDocument(
                            widget.dealerId,
                            doc.id,
                            accept: true,
                          ),
                          success: 'Document accepted',
                        ),
                  child: const Text('Accept'),
                ),
                TextButton(
                  onPressed: () => _rejectDocument(doc),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Reject'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _decisions(DealerApplication app) {
    Widget primary(
      String text,
      VoidCallback onPressed, {
      bool enabled = true,
    }) => FilledButton(
      onPressed: (enabled && !_busy) ? onPressed : null,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: Text(text),
    );
    Widget secondary(
      String text,
      VoidCallback onPressed, {
      bool destructive = false,
    }) => OutlinedButton(
      onPressed: _busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: destructive ? AppColors.error : null,
      ),
      child: Text(text),
    );

    final id = widget.dealerId;
    final allAccepted = app.documents
        .where((d) => d.type?.required == true)
        .every((d) => d.status == DocumentStatus.accepted);

    switch (app.status) {
      case DealerStatus.pending:
        return [
          primary(
            'Approve dealer',
            () => _run(() => _repo.approve(id), success: 'Dealer approved'),
            enabled: allAccepted && app.missingDocuments.isEmpty,
          ),
          if (!allAccepted)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Accept every required document to enable approval.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          secondary(
            'Request changes',
            () => _decide(
              'Request changes',
              'What should the dealer fix?',
              (r) => _repo.requestChanges(id, r),
              'Changes requested',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          secondary(
            'Reject application',
            () => _decide(
              'Reject application',
              'Why is this being rejected?',
              (r) => _repo.reject(id, r),
              'Application rejected',
            ),
            destructive: true,
          ),
        ];
      case DealerStatus.approved:
        return [
          secondary(
            'Suspend dealer',
            () => _decide(
              'Suspend dealer',
              'Why is this dealer being suspended?',
              (r) => _repo.suspend(id, r),
              'Dealer suspended',
            ),
            destructive: true,
          ),
        ];
      case DealerStatus.suspended:
        return [
          primary(
            'Reactivate dealer',
            () =>
                _run(() => _repo.reactivate(id), success: 'Dealer reactivated'),
          ),
        ];
      case DealerStatus.draft:
      case DealerStatus.needsChanges:
      case DealerStatus.rejected:
        return [
          Text(
            switch (app.status) {
              DealerStatus.rejected =>
                'This application was rejected. No further action is available.',
              DealerStatus.needsChanges =>
                'Waiting for the dealer to fix the requested changes and resubmit.',
              _ => 'The dealer has not submitted this application yet.',
            },
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ];
    }
  }
}
