import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/utils/relative_expiry.dart';
import 'package:url_launcher/url_launcher.dart';
import '../profile/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/market_service.dart';
import '../pond/pond_form_screen.dart';
import 'post_requirement_screen.dart';
import 'requirement_model.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.profile,
    this.showFarmSetupBanner = false,
    this.highlightRequirementId,
    this.onHighlightConsumed,
  });

  final UserProfile profile;
  final bool showFarmSetupBanner;
  final String? highlightRequirementId;
  final VoidCallback? onHighlightConsumed;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _nudgeDismissed = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _cardKeys = {};
  String? _activeHighlightId;
  bool _highlightVisible = false;
  bool _didAttemptHighlightScroll = false;

  @override
  void initState() {
    super.initState();
    _activeHighlightId = widget.highlightRequirementId;
  }

  @override
  void didUpdateWidget(MarketScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightRequirementId != oldWidget.highlightRequirementId &&
        widget.highlightRequirementId != null) {
      _activeHighlightId = widget.highlightRequirementId;
      _didAttemptHighlightScroll = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForRequirement(String id) =>
      _cardKeys.putIfAbsent(id, GlobalKey.new);

  void _maybeScrollToHighlight(List<MarketFeedItem> items) {
    if (_didAttemptHighlightScroll || _activeHighlightId == null) return;

    final targetId = _activeHighlightId!;
    final index = items.indexWhere((item) => item.requirement.id == targetId);
    _didAttemptHighlightScroll = true;

    if (index < 0) {
      widget.onHighlightConsumed?.call();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetContext = _cardKeys[targetId]?.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            alignment: 0.15,
          );
          setState(() => _highlightVisible = true);
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (!mounted) return;
            setState(() => _highlightVisible = false);
          });
        }
        widget.onHighlightConsumed?.call();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTrader = widget.profile.isTrader;

    final stream = isTrader
        ? MarketService.instance.watchFeedForTrader()
        : MarketService.instance.watchFeedForFarmer(widget.profile.region);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(l10n.titleMarket),
        centerTitle: true,
        actions: [
          if (isTrader && widget.profile.phoneVerified)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.postRequirement,
              onPressed: () => _openPostRequirement(context),
            ),
        ],
      ),
      floatingActionButton: isTrader && widget.profile.phoneVerified
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF005F73),
              onPressed: () => _openPostRequirement(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<MarketFeedItem>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${l10n.marketLoadError}\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isNotEmpty) {
            _maybeScrollToHighlight(items);
          } else if (_activeHighlightId != null && !_didAttemptHighlightScroll) {
            _didAttemptHighlightScroll = true;
            widget.onHighlightConsumed?.call();
          }

          final showPondExtras = widget.showFarmSetupBanner;
          final body = showPondExtras
              ? StreamBuilder(
                  stream: FirestoreService.instance.watchPonds(),
                  builder: (context, pondSnap) {
                    final pondCount = (pondSnap.data ?? []).length;
                    final showNudge = widget.showFarmSetupBanner &&
                        !_nudgeDismissed &&
                        _shouldShowDay7Nudge(pondCount);

                    return Column(
                      children: [
                        if (showNudge) _day7Nudge(context),
                        if (widget.showFarmSetupBanner && pondCount == 0)
                          _setupFarmCard(context),
                        Expanded(child: _buildRequirementList(context, items, isTrader)),
                      ],
                    );
                  },
                )
              : _buildRequirementList(context, items, isTrader);

          return body;
        },
      ),
    );
  }

  Widget _buildRequirementList(
    BuildContext context,
    List<MarketFeedItem> items,
    bool isTrader,
  ) {
    if (items.isEmpty) {
      return _emptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final req = items[index].requirement;
        final highlighted =
            _highlightVisible && req.id == _activeHighlightId;
        return KeyedSubtree(
          key: _keyForRequirement(req.id),
          child: _requirementCard(
            context,
            req,
            isTrader: isTrader,
            highlighted: highlighted,
          ),
        );
      },
    );
  }

  bool _shouldShowDay7Nudge(int pondCount) {
    if (pondCount > 0) return false;
    final created = widget.profile.createdAt;
    if (created == null) return false;
    return DateTime.now().difference(created).inDays >= 7;
  }

  Widget _day7Nudge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(l10n.marketDay7Nudge),
      leading: const Icon(Icons.water_outlined),
      actions: [
        TextButton(
          onPressed: () => _openAddPond(context),
          child: Text(l10n.setUpYourFarm),
        ),
        TextButton(
          onPressed: () => setState(() => _nudgeDismissed = true),
          child: Text(l10n.dismiss),
        ),
      ],
    );
  }

  Widget _setupFarmCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListTile(
        leading: const Icon(Icons.agriculture, color: Color(0xFF005F73)),
        title: Text(l10n.setUpYourFarm),
        subtitle: Text(l10n.setUpYourFarmDesc),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openAddPond(context),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.marketEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.marketEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requirementCard(
    BuildContext context,
    BuyerRequirement req, {
    required bool isTrader,
    bool highlighted = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final priceText = req.pricePerKg != null
        ? '₹${req.pricePerKg!.toStringAsFixed(0)}/${req.unit}'
        : l10n.priceOnRequest;
    final showExpiredBadge = requirementShowsExpiredBadge(
      status: req.status,
      expiresAt: req.expiresAt,
      now: now,
    );
    final statusLabel = showExpiredBadge
        ? l10n.requirementExpired
        : req.status.name;
    final expiryText = formatRequirementExpiry(req.expiresAt, now, l10n);
    final expiryIsPast = requirementIsPastExpiry(req.expiresAt, now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted ? const Color(0xFF005F73).withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: highlighted
            ? const BorderSide(color: Color(0xFF005F73), width: 2.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    req.traderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: showExpiredBadge
                      ? Colors.red.shade50
                      : null,
                  labelStyle: showExpiredBadge
                      ? TextStyle(color: Colors.red.shade700)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${req.quantityNeeded.toStringAsFixed(0)} ${req.unit} • '
              '${req.countRange.min}–${req.countRange.max} count',
            ),
            Text(priceText),
            Text(
              '${l10n.region}: ${req.region.join(", ")}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              expiryText,
              style: TextStyle(
                fontSize: 12,
                color: expiryIsPast ? Colors.red.shade700 : Colors.grey.shade600,
                fontStyle: expiryIsPast ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            if (isTrader && req.interestedCount > 0) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showInterestedFarmers(context, req),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.farmersInterested(req.interestedCount),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.teal.shade800,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (!isTrader)
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: showExpiredBadge
                        ? null
                        : () => _showInterested(context, req),
                    child: Text(l10n.interested),
                  ),
                  const SizedBox(width: 8),
                  if (req.traderPhone.trim().isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: showExpiredBadge
                          ? null
                          : () => _openWhatsApp(context, req.traderPhone),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                    )
                  else
                    Text(
                      l10n.contactUnavailable,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            if (isTrader &&
                req.status == RequirementStatus.open &&
                !showExpiredBadge)
              TextButton(
                onPressed: () {
                  MarketService.instance.updateRequirementStatus(
                    req.id,
                    RequirementStatus.fulfilled,
                  );
                },
                child: Text(l10n.markFulfilled),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInterestedFarmers(
    BuildContext context,
    BuyerRequirement req,
  ) async {
    if (req.interestedCount <= 0) return;

    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: FutureBuilder<List<InterestedFarmer>>(
              future: MarketService.instance.fetchInterestedFarmers(req.id),
              builder: (context, snapshot) {
                final l10n = AppLocalizations.of(context)!;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.interestedFarmersTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.interestedFarmersTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.interestedFarmersLoadError),
                    ],
                  );
                }

                final farmers = snapshot.data ?? const <InterestedFarmer>[];
                if (farmers.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.interestedFarmersTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.interestedFarmersEmpty),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.interestedFarmersTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.farmersInterested(farmers.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: farmers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final farmer = farmers[index];
                          final regionLabel = farmer.region.isEmpty
                              ? '—'
                              : farmer.region;
                          final hasPhone = farmer.phoneNumber.trim().isNotEmpty;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              farmer.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${l10n.region}: $regionLabel'),
                            trailing: hasPhone
                                ? OutlinedButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(sheetContext);
                                      await _openWhatsApp(
                                        parentContext,
                                        farmer.phoneNumber,
                                      );
                                    },
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('WhatsApp'),
                                  )
                                : Text(
                                    l10n.noContact,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInterested(BuildContext context, BuyerRequirement req) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await MarketService.instance.recordInterest(req.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.interestRecordError}\n$e')),
      );
      return;
    }

    if (!context.mounted) return;
    final parentContext = context;
    final traderPhone = req.traderPhone.trim();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.traderContact,
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (traderPhone.isEmpty)
              Text(
                l10n.contactUnavailable,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              )
            else ...[
              SelectableText(traderPhone, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: traderPhone));
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (!parentContext.mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(l10n.phoneCopied)),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(l10n.copyPhone),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await _openWhatsApp(parentContext, traderPhone);
                },
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _whatsappDigits(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('91') && digits.length == 12) {
      // already country-coded
    } else if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context)!;
    final digits = _whatsappDigits(phone);
    if (digits.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final uris = [
      Uri.parse('https://wa.me/$digits'),
      Uri.parse('whatsapp://send?phone=$digits'),
    ];

    for (final uri in uris) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {
        // Try next scheme.
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n.copyPhone}: tap the number above, or install WhatsApp.',
        ),
      ),
    );
  }

  void _openPostRequirement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostRequirementScreen(profile: widget.profile),
      ),
    );
  }

  void _openAddPond(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PondFormScreen(
          mode: PondFormMode.create,
          onSave: (pond) async {
            try {
              await FirestoreService.instance.upsertPond(pond);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')),
              );
            }
          },
        ),
      ),
    );
  }
}
