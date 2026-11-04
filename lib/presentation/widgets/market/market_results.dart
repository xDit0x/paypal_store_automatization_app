import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:store_automatization_app/common/helpers/stocky_format.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/stocky_ui.dart';

/// Bandera a partir del código ISO ("ES" -> 🇪🇸).
String countryFlag(String code) {
  final upper = code.toUpperCase();
  if (upper.length != 2) return '🌍';
  return String.fromCharCodes(upper.codeUnits.map((c) => c + 127397));
}

/// Las 3 mejores ofertas del estudio de mercado, con todo el detalle.
class MarketResults extends StatelessWidget {
  const MarketResults({
    super.key,
    required this.research,
    required this.onChoose,
    this.busyOfferId,
  });

  final MarketResearch research;
  final void Function(MarketOption option) onChoose;
  final String? busyOfferId;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    final l10n = context.l10n;

    // Sin ofertas, el asistente ya lo explica en su mensaje: solo se enseñan
    // los resultados de internet, si los hay.
    if (research.options.isEmpty) {
      return research.webLeads.isEmpty ? const SizedBox.shrink() : _WebLeads(leads: research.webLeads);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
          child: Text(
            [
              l10n.marketCompared(research.compared, research.countries.length),
              if (research.countries.isNotEmpty) research.countries.map(countryFlag).join(' '),
            ].join('  '),
            style: t.footnote,
          ),
        ),
        if (research.demoDirectory)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RPill(l10n.marketDemoBadge, tone: RPillTone.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.marketDemoNotice, style: t.caption),
                ),
              ],
            ),
          ),
        for (var i = 0; i < research.options.length; i++) ...[
          _OptionCard(
            rank: i + 1,
            option: research.options[i],
            busy: busyOfferId == research.options[i].offerId,
            disabled: busyOfferId != null,
            demo: research.demoDirectory,
            onChoose: () => onChoose(research.options[i]),
          ),
          const SizedBox(height: 10),
        ],
        if (!research.liveRates)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(l10n.marketFxFallback, style: t.caption),
          ),
        if (research.webLeads.isNotEmpty) _WebLeads(leads: research.webLeads),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.rank,
    required this.option,
    required this.busy,
    required this.disabled,
    required this.onChoose,
    this.demo = false,
  });

  final int rank;
  final MarketOption option;
  final bool busy;
  final bool disabled;
  final VoidCallback onChoose;

  /// El distribuidor es del directorio de demostración (empresa ficticia).
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final place = [option.city, option.country].whereType<String>().join(', ');

    final tags = <Widget>[
      if (demo) RPill(l10n.marketDemoBadge, tone: RPillTone.warning),
      for (final tag in option.tags)
        RPill(
          switch (tag) {
            MarketTag.cheapest => l10n.marketTagCheapest,
            MarketTag.fastest => l10n.marketTagFastest,
            MarketTag.bestRated => l10n.marketTagBestRated,
          },
          tone: tag == MarketTag.cheapest ? RPillTone.info : RPillTone.neutral,
        ),
      if (option.overBudget) RPill(l10n.marketTagOverBudget, tone: RPillTone.warning),
    ];

    return RCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank == 1 ? p.accent : p.fill,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: rank == 1 ? p.onAccent : p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.distributorName, style: t.headline),
                    const SizedBox(height: 2),
                    Text('${countryFlag(option.country)}  $place', style: t.footnote),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.euros(option.unitLandedEur),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.navy),
                  ),
                  Text(l10n.marketPerUnit(option.unit), style: t.caption),
                ],
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: tags),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: p.separator),
          const SizedBox(height: 10),
          _Line(
            l10n.marketOrderQty(option.orderQty, option.unit),
            l10n.marketMinPack(option.minQty, option.packSize),
          ),
          _Line(l10n.marketGoods, l10n.euros(option.goodsEur)),
          _Line(
            l10n.marketShipping,
            option.shippingEur == 0 ? l10n.marketShippingFree : l10n.euros(option.shippingEur),
          ),
          if (option.dutiesEur > 0) _Line(l10n.marketDuties, l10n.euros(option.dutiesEur)),
          _Line(l10n.marketTotal, l10n.euros(option.totalEur), strong: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Meta(CupertinoIcons.cube_box, l10n.marketLeadDays(option.leadDays)),
              _Meta(CupertinoIcons.star_fill, option.rating.toStringAsFixed(1)),
              if (option.currency.toUpperCase() != 'EUR')
                _Meta(
                  CupertinoIcons.money_dollar_circle,
                  l10n.marketOriginalPrice(l10n.euros(option.unitPrice, option.currency)),
                ),
            ],
          ),
          if (option.outsideEu) ...[
            const SizedBox(height: 6),
            Text(l10n.marketOutsideEu, style: t.caption),
          ],
          if (option.notes != null) ...[
            const SizedBox(height: 6),
            Text(option.notes!, style: t.footnote),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: disabled ? null : onChoose,
              style: FilledButton.styleFrom(
                backgroundColor: rank == 1 ? p.accent : p.blueSoft,
                foregroundColor: rank == 1 ? p.onAccent : p.navy,
                disabledBackgroundColor: p.fill,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: busy
                  ? const CupertinoActivityIndicator(radius: 9)
                  : Text(l10n.marketChoose),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final style = TextStyle(
      fontSize: 14,
      color: strong ? p.ink : p.inkSecondary,
      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(color: p.ink)),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: p.inkSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: p.inkSecondary)),
      ],
    );
  }
}

class _WebLeads extends StatelessWidget {
  const _WebLeads({required this.leads});

  final List<WebLead> leads;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    return RCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.marketWebTitle, style: t.headline),
          Text(l10n.marketWebHint, style: t.caption),
          const SizedBox(height: 6),
          for (final lead in leads)
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(lead.url);
                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.globe, size: 16, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: p.ink),
                          ),
                          Text(lead.domain, style: t.caption),
                        ],
                      ),
                    ),
                    const RChevron(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
