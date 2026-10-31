import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/dealer_application.dart';
import '../providers/dealer_application_provider.dart';

/// Shown to dealers until an admin approves them. Everything else in the dealer
/// portal is hidden until then (the API enforces this too).
class DealerApplicationScreen extends ConsumerStatefulWidget {
  const DealerApplicationScreen({super.key});

  @override
  ConsumerState<DealerApplicationScreen> createState() => _DealerApplicationScreenState();
}

class _DealerApplicationScreenState extends ConsumerState<DealerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _gstin = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  String? _loadedFor; // application id the controllers were filled from
  bool _busy = false;

  @override
  void dispose() {
    _business.dispose();
    _gstin.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  void _fill(DealerApplication app) {
    if (_loadedFor == app.id) return;
    _loadedFor = app.id;
    _business.text = app.businessName;
    _gstin.text = app.gstin ?? '';
    _address.text = app.address ?? '';
    _city.text = app.city;
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (success != null && mounted) _toast(success);
    } catch (e) {
      if (mounted) _toast(apiErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ));
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(
      () => ref.read(dealerApplicationProvider.notifier).saveDetails(
            businessName: _business.text.trim(),
            gstin: _gstin.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
          ),
      success: 'Details saved',
    );
  }

  Future<void> _pickAndUpload(DocumentType type) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2200,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _run(
      () => ref.read(dealerApplicationProvider.notifier).upload(type, picked.name, bytes),
      success: '${type.label} uploaded',
    );
  }

  Future<void> _submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit for review?'),
        content: const Text(
          'You will not be able to edit your details or documents while we review them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(dealerApplicationProvider.notifier).submit();
      await ref.read(authControllerProvider.notifier).checkCurrentSession();
    }, success: 'Application submitted');
  }

  Future<void> _refresh() async {
    await ref.read(dealerApplicationProvider.notifier).refresh();
    // The backend decides when we are approved; re-read the profile so the app unlocks.
    await ref.read(authControllerProvider.notifier).checkCurrentSession();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(dealerApplicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer application'),
        actions: [
          IconButton(
            tooltip: 'Check status',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _refresh,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: app.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: AppSpacing.md),
                Text(apiErrorMessage(e), textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(onPressed: _refresh, child: const Text('Try again')),
              ],
            ),
          ),
        ),
        data: (data) {
          _fill(data);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusBanner(app: data),
                        const SizedBox(height: AppSpacing.lg),
                        _detailsCard(data),
                        const SizedBox(height: AppSpacing.lg),
                        _documentsCard(data),
                        const SizedBox(height: AppSpacing.xxl),
                        if (data.editable)
                          FilledButton(
                            onPressed: (data.canSubmit && !_busy) ? _submit : null,
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            child: _busy
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Submit for review'),
                          ),
                        if (data.editable && !data.canSubmit)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'Add your address and upload the three required documents to submit.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _detailsCard(DealerApplication app) {
    final enabled = app.editable && !_busy;
    return _card(
      title: 'Business details',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _business,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Business name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your business name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _city,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your city' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _address,
              enabled: enabled,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Showroom address'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your showroom address' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _gstin,
              enabled: enabled,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'GSTIN (optional)'),
            ),
            if (app.editable) ...[
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: enabled ? _saveDetails : null,
                  child: const Text('Save details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _documentsCard(DealerApplication app) {
    return _card(
      title: 'Documents',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Upload clear photos or scans. Only the Revora review team can see them.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final type in DocumentType.values)
            _DocumentRow(
              type: type,
              document: app.documentOf(type),
              editable: app.editable && !_busy,
              onUpload: () => _pickAndUpload(type),
              onRemove: (id) => _run(() => ref.read(dealerApplicationProvider.notifier).remove(id)),
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final DealerApplication app;
  const _StatusBanner({required this.app});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color fg, Color bg, String title, String body) = switch (app.status) {
      DealerStatus.draft => (
          Icons.edit_note, AppColors.info, AppColors.infoBg,
          'Complete your application',
          'Add your business details and documents, then submit for review.',
        ),
      DealerStatus.pending => (
          Icons.hourglass_top, AppColors.warning, AppColors.warningBg,
          'Under review',
          'Our team is checking your documents. This usually takes 1–2 working days.',
        ),
      DealerStatus.needsChanges => (
          Icons.report_problem_outlined, AppColors.warning, AppColors.warningBg,
          'Changes needed',
          app.statusReason ?? 'Please update your application and submit it again.',
        ),
      DealerStatus.rejected => (
          Icons.cancel_outlined, AppColors.error, AppColors.errorBg,
          'Application not approved',
          app.statusReason ?? 'Contact support if you think this is a mistake.',
        ),
      DealerStatus.suspended => (
          Icons.block, AppColors.error, AppColors.errorBg,
          'Account suspended',
          app.statusReason ?? 'Contact support for details.',
        ),
      DealerStatus.approved => (
          Icons.verified_outlined, AppColors.success, AppColors.successBg,
          'Approved',
          'Your dealership is verified.',
        ),
    };
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge.copyWith(color: fg)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final DocumentType type;
  final DealerDocument? document;
  final bool editable;
  final VoidCallback onUpload;
  final void Function(String id) onRemove;

  const _DocumentRow({
    required this.type,
    required this.document,
    required this.editable,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final doc = document;
    final (String label, Color color) = switch (doc?.status) {
      null => (type.required ? 'Required' : 'Optional', AppColors.textSecondary),
      DocumentStatus.pending => ('Uploaded · awaiting review', AppColors.info),
      DocumentStatus.accepted => ('Accepted', AppColors.success),
      DocumentStatus.rejected => ('Rejected', AppColors.error),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(type.hint, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      doc == null ? Icons.circle_outlined
                          : doc.status == DocumentStatus.accepted ? Icons.check_circle
                          : doc.status == DocumentStatus.rejected ? Icons.error : Icons.schedule,
                      size: 16, color: color,
                    ),
                    const SizedBox(width: 6),
                    Flexible(child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color))),
                  ],
                ),
                if (doc?.status == DocumentStatus.rejected && doc?.reviewNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(doc!.reviewNote!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                  ),
              ],
            ),
          ),
          if (editable) ...[
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: onUpload,
              child: Text(doc == null ? 'Upload' : 'Replace'),
            ),
            if (doc != null)
              IconButton(
                tooltip: 'Remove ${type.label}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onRemove(doc.id),
              ),
          ],
        ],
      ),
    );
  }
}
