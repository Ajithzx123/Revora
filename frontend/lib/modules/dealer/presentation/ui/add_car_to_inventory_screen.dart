import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/master_data/master_data.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../providers/inventory_provider.dart';

const _maxPhotos = 8;
final _registrationPattern = RegExp(r'^([A-Z]{2}\d{1,2}[A-Z]{0,3}\d{4}|\d{2}BH\d{4}[A-Z]{1,2})$');

class _PendingPhoto {
  final String name;
  final Uint8List bytes;
  const _PendingPhoto(this.name, this.bytes);
}

/// Add a car to stock, or edit one (when [existing] is given).
/// Photos in edit mode are uploaded the moment they are picked; in add mode they
/// are held until the car has been created.
class AddCarToInventoryScreen extends ConsumerStatefulWidget {
  final Vehicle? existing;
  const AddCarToInventoryScreen({super.key, this.existing});

  @override
  ConsumerState<AddCarToInventoryScreen> createState() => _AddCarToInventoryScreenState();
}

class _AddCarToInventoryScreenState extends ConsumerState<AddCarToInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final VehicleDraft _draft;
  final _registration = TextEditingController();
  final _variant = TextEditingController();
  final _km = TextEditingController();
  final _price = TextEditingController();
  final _minPrice = TextEditingController();
  final _description = TextEditingController();

  final List<_PendingPhoto> _pending = [];
  Vehicle? _vehicle; // the saved car (edit mode, or after creating it)
  bool _busy = false;
  String? _progress;
  String? _error;
  String? _choiceError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.existing;
    _draft = _vehicle != null ? VehicleDraft.from(_vehicle!) : VehicleDraft();
    _registration.text = _draft.registrationNo ?? '';
    _variant.text = _draft.variant ?? '';
    _km.text = _draft.km?.toString() ?? '';
    _price.text = _draft.price?.toString() ?? '';
    _minPrice.text = _draft.minPrice?.toString() ?? '';
    _description.text = _draft.description ?? '';
  }

  @override
  void dispose() {
    for (final c in [_registration, _variant, _km, _price, _minPrice, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- photos ----
  int get _photoCount => (_vehicle?.images.length ?? 0) + _pending.length;

  Future<void> _pickPhotos() async {
    final room = _maxPhotos - _photoCount;
    if (room <= 0) {
      _toast('A car can have at most $_maxPhotos photos.', error: true);
      return;
    }
    final picked = await ImagePicker().pickMultiImage(maxWidth: 2200, imageQuality: 85);
    if (picked.isEmpty) return;
    final chosen = picked.take(room).toList();
    if (picked.length > room) _toast('Only $room more photo${room == 1 ? '' : 's'} fit. The rest were skipped.');

    for (final file in chosen) {
      final bytes = await file.readAsBytes();
      if (_editing || _vehicle != null) {
        await _guard(() => ref.read(inventoryProvider.notifier).addPhoto(_vehicle!.id, file.name, bytes).then(_setVehicle));
      } else {
        setState(() => _pending.add(_PendingPhoto(file.name, bytes)));
      }
    }
  }

  void _setVehicle(Vehicle v) {
    if (mounted) setState(() => _vehicle = v);
  }

  // ---- save ----
  bool _validChoices() {
    String? problem;
    if (_draft.make == null) {
      problem = 'Choose the make.';
    } else if (_draft.model == null) {
      problem = 'Choose the model.';
    } else if (_draft.year == null) {
      problem = 'Choose the year.';
    } else if (_draft.fuel == null) {
      problem = 'Choose the fuel type.';
    } else if (_draft.transmission == null) {
      problem = 'Choose the transmission.';
    }
    setState(() => _choiceError = problem);
    return problem == null;
  }

  int? _digits(TextEditingController c) {
    final text = c.text.replaceAll(RegExp(r'[^0-9]'), '');
    return text.isEmpty ? null : int.parse(text);
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final choicesOk = _validChoices();
    if (!formOk || !choicesOk) return;

    _draft
      ..registrationNo = _registration.text.trim()
      ..variant = _variant.text
      ..km = _digits(_km)
      ..price = _digits(_price)
      ..minPrice = _digits(_minPrice)
      ..description = _description.text;

    await _guard(() async {
      final notifier = ref.read(inventoryProvider.notifier);
      final saved = _vehicle == null ? await notifier.create(_draft) : await notifier.edit(_vehicle!.id, _draft);
      _vehicle = saved;

      var failed = 0;
      for (var i = 0; i < _pending.length; i++) {
        if (mounted) setState(() => _progress = 'Uploading photo ${i + 1} of ${_pending.length}...');
        try {
          _vehicle = await notifier.addPhoto(saved.id, _pending[i].name, _pending[i].bytes);
        } catch (_) {
          failed++;
        }
      }
      _pending.clear();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (failed > 0) {
        // The car exists; stay on its edit screen so the dealer can retry the photos.
        setState(() => _progress = null);
        _toast('Car saved, but $failed photo${failed == 1 ? '' : 's'} could not be uploaded. Add them again below.', error: true);
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editing ? 'Changes saved.' : 'Car added to your inventory.')));
    });
    if (mounted) setState(() => _progress = null);
  }

  Future<void> _changeStatus(String status, String done) async {
    await _guard(() async {
      await ref.read(inventoryProvider.notifier).setStatus(_vehicle!.id, status);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    });
  }

  Future<void> _confirm({required String title, required String body, required String action, required Future<void> Function() onYes, bool destructive = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok == true) await onYes();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : null));
  }

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    final md = ref.watch(masterDataProvider).valueOrNull ?? MasterData.bundled;
    final t = Theme.of(context).textTheme;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = _vehicle != null;
    final years = [for (var y = DateTime.now().year + 1; y >= md.minYear; y--) y];

    return Scaffold(
      appBar: AppBar(title: Text(saved && _editing ? 'Edit car' : 'Add a car')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Section(
                            title: 'Photos',
                            subtitle: 'Add up to $_maxPhotos. The first photo is the cover buyers see.',
                            child: _photoGrid(),
                          ),
                          _Section(
                            title: 'The car',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _registration,
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]'))],
                                  decoration: const InputDecoration(
                                    labelText: 'Registration number',
                                    helperText: 'Example: KA01AB1234. Each car can be listed once.',
                                    helperMaxLines: 2,
                                  ),
                                  validator: (v) {
                                    final n = (v ?? '').replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
                                    if (n.isEmpty) return 'Enter the registration number';
                                    if (!_registrationPattern.hasMatch(n)) return 'That does not look like a registration number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                DropdownButtonFormField<String>(
                                  initialValue: _draft.make,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  dropdownColor: AppColors.surface,
                                  decoration: const InputDecoration(labelText: 'Make'),
                                  items: [for (final m in md.makeNames) DropdownMenuItem(value: m, child: Text(m))],
                                  onChanged: (v) => setState(() {
                                    _draft.make = v;
                                    _draft.model = null;
                                  }),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(_draft.make),
                                  initialValue: _draft.model,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  dropdownColor: AppColors.surface,
                                  decoration: InputDecoration(
                                    labelText: 'Model',
                                    helperText: _draft.make == null ? 'Choose a make first' : null,
                                  ),
                                  items: [for (final m in md.modelsOf(_draft.make)) DropdownMenuItem(value: m, child: Text(m))],
                                  onChanged: _draft.make == null ? null : (v) => setState(() => _draft.model = v),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextFormField(
                                  controller: _variant,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(labelText: 'Variant (optional)', hintText: 'e.g. Asta 1.2 AMT'),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                DropdownButtonFormField<int>(
                                  initialValue: _draft.year,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  dropdownColor: AppColors.surface,
                                  decoration: const InputDecoration(labelText: 'Year'),
                                  items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                                  onChanged: (v) => setState(() => _draft.year = v),
                                ),
                              ],
                            ),
                          ),
                          _Section(
                            title: 'Details',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Label('Fuel'),
                                _Chips(
                                  options: md.fuels,
                                  selected: _draft.fuel,
                                  onChanged: (v) => setState(() => _draft.fuel = v),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const _Label('Transmission'),
                                _Chips(
                                  options: md.transmissions,
                                  selected: _draft.transmission,
                                  onChanged: (v) => setState(() => _draft.transmission = v),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const _Label('Body type (optional)'),
                                _Chips(
                                  options: md.bodyTypes,
                                  selected: _draft.bodyType,
                                  onChanged: (v) => setState(() => _draft.bodyType = v),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextFormField(
                                  controller: _km,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Kilometres driven', suffixText: 'km'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Enter the kilometres driven' : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const _Label('Owners so far'),
                                _Chips(
                                  options: const ['1', '2', '3', '4'],
                                  labels: const {'1': 'First owner', '2': '2nd', '3': '3rd', '4': '4th+'},
                                  selected: _draft.owners.toString(),
                                  required: true,
                                  onChanged: (v) => setState(() => _draft.owners = int.parse(v ?? '1')),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                DropdownButtonFormField<String>(
                                  initialValue: _draft.color,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  dropdownColor: AppColors.surface,
                                  decoration: const InputDecoration(labelText: 'Colour (optional)'),
                                  items: [for (final c in md.colors) DropdownMenuItem(value: c, child: Text(c))],
                                  onChanged: (v) => setState(() => _draft.color = v),
                                ),
                              ],
                            ),
                          ),
                          _Section(
                            title: 'Price',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _price,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Asking price',
                                    prefixText: '₹ ',
                                    helperText: _digits(_price) == null ? null : PriceFormatter.formatINR(_digits(_price)!),
                                  ),
                                  validator: (v) {
                                    final n = _digits(_price);
                                    if (n == null) return 'Enter the asking price';
                                    if (n < 50000) return 'Price looks too low';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextFormField(
                                  controller: _minPrice,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    labelText: 'Lowest price you would accept (optional)',
                                    prefixText: '₹ ',
                                    helperText: 'Private. Buyers never see this.',
                                  ),
                                  validator: (v) {
                                    final low = _digits(_minPrice);
                                    final ask = _digits(_price);
                                    if (low != null && ask != null && low > ask) return 'Cannot be above the asking price';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          _Section(
                            title: 'Anything else?',
                            child: TextFormField(
                              controller: _description,
                              maxLength: 1000,
                              minLines: 3,
                              maxLines: 6,
                              decoration: const InputDecoration(hintText: 'Service history, accessories, condition...'),
                            ),
                          ),
                          if (_choiceError != null) _Banner(message: _choiceError!),
                          if (_error != null) _Banner(message: _error!),
                          if (saved && _editing) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text('Manage', style: t.titleSmall),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              children: [
                                if (!_vehicle!.isSold)
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirm(
                                              title: 'Mark as sold?',
                                              body: 'Any quotes on this car will be marked unavailable so buyers cannot accept them.',
                                              action: 'Mark as sold',
                                              onYes: () => _changeStatus('sold', 'Marked as sold.'),
                                            ),
                                    child: const Text('Mark as sold'),
                                  ),
                                if (_vehicle!.status == 'reserved' || _vehicle!.isSold)
                                  OutlinedButton(
                                    onPressed: _busy ? null : () => _changeStatus('available', 'Back in stock.'),
                                    child: const Text('Put back in stock'),
                                  )
                                else if (!_vehicle!.isSold)
                                  OutlinedButton(
                                    onPressed: _busy ? null : () => _changeStatus('reserved', 'Marked as reserved.'),
                                    child: const Text('Reserve'),
                                  ),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                  onPressed: _busy
                                      ? null
                                      : () => _confirm(
                                            title: 'Delete this car?',
                                            body: 'Its photos are removed too. This cannot be undone.',
                                            action: 'Delete',
                                            destructive: true,
                                            onYes: () => _guard(() async {
                                              await ref.read(inventoryProvider.notifier).remove(_vehicle!.id);
                                              if (!mounted) return;
                                              navigator.pop();
                                              messenger.showSnackBar(const SnackBar(content: Text('Car deleted.')));
                                            }),
                                          ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                ),
                                if (_progress != null) ...[const SizedBox(width: 12), Text(_progress!)],
                              ],
                            )
                          : Text(_editing ? 'Save changes' : (saved ? 'Save and finish' : 'Add car')),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoGrid() {
    final images = _vehicle?.images ?? const <VehicleImage>[];
    final tiles = <Widget>[
      for (var i = 0; i < images.length; i++)
        _PhotoTile(
          provider: NetworkImage(images[i].url),
          isCover: i == 0,
          onRemove: _busy ? null : () => _guard(() => ref.read(inventoryProvider.notifier).removePhoto(_vehicle!.id, images[i].id).then(_setVehicle)),
          onMakeCover: (i == 0 || _busy) ? null : () => _guard(() => ref.read(inventoryProvider.notifier).makeCover(_vehicle!.id, images[i].id).then(_setVehicle)),
        ),
      for (var i = 0; i < _pending.length; i++)
        _PhotoTile(
          provider: MemoryImage(_pending[i].bytes),
          isCover: images.isEmpty && i == 0,
          onRemove: _busy ? null : () => setState(() => _pending.removeAt(i)),
        ),
      if (_photoCount < _maxPhotos) _AddTile(onTap: _busy ? null : _pickPhotos),
    ];
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }
}

// ---------- building blocks ----------
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Section({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleLarge),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: t.bodySmall)],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Chips extends StatelessWidget {
  final List<String> options;
  final Map<String, String> labels;
  final String? selected;
  final bool required;
  final ValueChanged<String?> onChanged;

  const _Chips({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labels = const {},
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(labels[o] ?? o),
            selected: selected == o,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: selected == o ? Colors.white : AppColors.textPrimary),
            onSelected: (_) => onChanged(required ? o : (selected == o ? null : o)),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ImageProvider provider;
  final bool isCover;
  final VoidCallback? onRemove;
  final VoidCallback? onMakeCover;

  const _PhotoTile({required this.provider, required this.isCover, this.onRemove, this.onMakeCover});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: provider, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColors.primarySubtle)),
          if (isCover)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                child: Text('COVER', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onAccent, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ),
          if (onRemove != null)
            Positioned(
              right: 2,
              top: 2,
              child: Semantics(
                button: true,
                label: 'Remove photo',
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (onMakeCover != null)
            Positioned(
              left: 2,
              top: 2,
              child: Semantics(
                button: true,
                label: 'Make cover photo',
                child: GestureDetector(
                  onTap: onMakeCover,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.star_outline_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add photos',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
              SizedBox(height: 2),
              Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  const _Banner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
