import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

enum _Limit { monthly, perOrder, approval }

/// Pestaña Reglas: las reglas de gasto que el código hace cumplir, y la cuenta.
class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RTabPage(
      builder: (context, state) {
        final t = context.rt;
        final r = state.rules;
        final c = state.currency;
        final allowed = r.allowedSupplierIds.map(state.supplierName).toList();

        return [
          const RLargeTitle(
            'Reglas',
            subtitle: 'El agente solo paga si se cumplen todas',
          ),
          const SizedBox(height: 18),
          const RSectionTitle('Gasto', small: true),
          RInsetGroup(
            children: [
              _RuleRow(
                text:
                    'No gastes más de ${eurosShort(r.monthlyLimit, c)} al mes',
                pill: const RPill('Tope mensual', tone: RPillTone.info),
                detail:
                    'Llevas ${eurosShort(state.spentThisMonth.roundToDouble(), c)}',
                onTap: () => _editLimit(context, state, _Limit.monthly),
              ),
              _RuleRow(
                text:
                    'Ningún pedido puede pasar de ${eurosShort(r.maxPerOrder, c)}',
                pill: const RPill('Máximo por pedido'),
                onTap: () => _editLimit(context, state, _Limit.perOrder),
              ),
              _RuleRow(
                text: r.requireApprovalAbove <= 0
                    ? 'Pregúntame por cualquier pedido'
                    : 'Si un pedido pasa de ${eurosShort(r.requireApprovalAbove, c)}, pregúntame',
                pill: const RPill('Pide aprobación', tone: RPillTone.warning),
                onTap: () => _editLimit(context, state, _Limit.approval),
              ),
              _RuleRow(
                text: allowed.isEmpty
                    ? 'Puedes comprar a cualquier proveedor'
                    : 'Compra solo a ${allowed.join(', ')}',
                pill: const RPill('Proveedores', tone: RPillTone.transit),
                onTap: () => _editSuppliers(context, state),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Toca una regla para cambiarla. Las reglas se comprueban en el sistema, no en la IA.',
              style: t.caption,
            ),
          ),
          const SizedBox(height: 22),
          const RSectionTitle('Cuenta', small: true),
          const _AccountGroup(),
        ];
      },
    );
  }

  Future<void> _editLimit(
    BuildContext context,
    RestockState state,
    _Limit limit,
  ) async {
    final r = state.rules;
    final (title, current, min, hint) = switch (limit) {
      _Limit.monthly => (
          'Tope mensual',
          r.monthlyLimit,
          r.maxPerOrder,
          'No puede ser menor que el máximo por pedido.',
        ),
      _Limit.perOrder => (
          'Máximo por pedido',
          r.maxPerOrder,
          0.01,
          'Tiene que ser mayor que 0.',
        ),
      _Limit.approval => (
          'Pedir aprobación a partir de',
          r.requireApprovalAbove,
          0.0,
          'Con 0 me preguntas por cualquier pedido.',
        ),
    };

    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.rp.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AmountSheet(
        title: title,
        initial: current,
        min: min,
        hint: hint,
        currency: state.currency,
      ),
    );
    if (value == null || !context.mounted) return;

    final updated = switch (limit) {
      _Limit.monthly => r.copyWith(monthlyLimit: value),
      _Limit.perOrder => r.copyWith(maxPerOrder: value),
      _Limit.approval => r.copyWith(requireApprovalAbove: value),
    };
    await _save(context, updated);
  }

  Future<void> _editSuppliers(BuildContext context, RestockState state) async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.rp.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SuppliersSheet(state: state),
    );
    if (selected == null || !context.mounted) return;
    await _save(context, state.rules.copyWith(allowedSupplierIds: selected));
  }

  Future<void> _save(BuildContext context, SpendingRules rules) async {
    final error = await context.read<RestockCubit>().saveRules(rules);
    if (!context.mounted) return;
    if (error != null) {
      showRestockSnack(
        context,
        error,
        title: 'No se pudieron guardar las reglas',
        tone: RSnackTone.warning,
      );
    } else {
      showRestockSnack(
        context,
        'Tus límites de gasto y proveedores ya están aplicados.',
        title: 'Reglas guardadas',
        tone: RSnackTone.success,
      );
    }
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.text,
    required this.pill,
    required this.onTap,
    this.detail,
  });

  final String text;
  final Widget pill;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“$text”', style: t.body),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      pill,
                      if (detail != null) ...[
                        const SizedBox(width: 8),
                        Flexible(child: Text(detail!, style: t.footnote)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const RChevron(),
          ],
        ),
      ),
    );
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.initial,
    required this.min,
    required this.hint,
    required this.currency,
  });

  final String title;
  final double initial;

  /// Valor mínimo que se puede guardar.
  final double min;

  /// Explicación de la regla, para que se entienda por qué el mínimo.
  final String hint;
  final String currency;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == widget.initial.roundToDouble()
        ? widget.initial.round().toString()
        : widget.initial.toStringAsFixed(2).replaceAll('.', ','),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value =>
      double.tryParse(_controller.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RSectionTitle(widget.title),
            RCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                      decoration: restockPlainInput(context, '0'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Text(
                    eurosShort(0, widget.currency).replaceAll('0', '').trim(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: p.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.hint,
              style: t.caption,
            ),
            const SizedBox(height: 16),
            RPrimaryButton(
              'Guardar',
              onPressed: (_value ?? double.negativeInfinity) >= widget.min
                  ? () => Navigator.pop(context, _value)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuppliersSheet extends StatefulWidget {
  const _SuppliersSheet({required this.state});

  final RestockState state;

  @override
  State<_SuppliersSheet> createState() => _SuppliersSheetState();
}

class _SuppliersSheetState extends State<_SuppliersSheet> {
  late final Set<String> _selected = {...widget.state.rules.allowedSupplierIds};

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final suppliers = widget.state.suppliers.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RSectionTitle('Proveedores permitidos'),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'Si no marcas ninguno, el agente puede comprar a todos.',
                style: t.footnote,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: RInsetGroup(
                  children: [
                    for (final s in suppliers)
                      CheckboxListTile.adaptive(
                        value: _selected.contains(s.id),
                        activeColor: p.accent,
                        title: Text(s.name, style: t.body),
                        subtitle: s.category == null
                            ? null
                            : Text(s.category!, style: t.footnote),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(s.id);
                          } else {
                            _selected.remove(s.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            RPrimaryButton(
              'Guardar',
              onPressed: () => Navigator.pop(context, _selected.toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup();

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final email = context.watch<AuthCubit>().state.user?.email;
    final mode = context.watch<ThemeCubit>().state;
    final segmentStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: p.ink,
    );

    return RInsetGroup(
      children: [
        if (email != null)
          RListRow(
            title: 'Sesión',
            trailing: Flexible(
              child: Text(
                email,
                style: t.footnote,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Text('Apariencia', style: t.body),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoSlidingSegmentedControl<ThemeMode>(
                  groupValue: mode,
                  backgroundColor: p.fill,
                  thumbColor: p.surface,
                  children: {
                    ThemeMode.system: Text('Auto', style: segmentStyle),
                    ThemeMode.light: Text('Claro', style: segmentStyle),
                    ThemeMode.dark: Text('Oscuro', style: segmentStyle),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      context.read<ThemeCubit>().updateTheme(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _signOut(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Row(
              children: [
                Text('Cerrar sesión', style: t.body.copyWith(color: p.warning)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }
}
