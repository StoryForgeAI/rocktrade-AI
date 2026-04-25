import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_models.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  final _dashboardService = DashboardService(Supabase.instance.client);
  final _analysisService = AnalysisService(Supabase.instance.client);
  final _billingService = BillingService(Supabase.instance.client);
  final _authService = AuthService(Supabase.instance.client);
  final _pickerService = PickerService();

  DashboardState? _dashboard;
  TradeAnalysis? _latestAnalysis;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  String? _selectedMimeType;
  bool _isBusy = false;
  bool _isDragging = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final dashboard = await _dashboardService.loadDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
      });
    } on AuthException catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack(error.toString());
    }
  }

  Future<void> _pickImage() async {
    final selection = await _pickerService.pickImage();
    if (selection == null) return;

    setState(() {
      _selectedImageBytes = selection.bytes;
      _selectedFileName = selection.fileName;
      _selectedMimeType = selection.mimeType;
    });
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    final file = details.files.first;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _selectedFileName = file.name;
      _selectedMimeType = file.mimeType ?? 'image/png';
      _isDragging = false;
    });
  }

  Future<void> _runAnalysis() async {
    final profile = _dashboard?.profile;
    if (_selectedImageBytes == null || _selectedFileName == null || profile == null) {
      _showSnack('Choose a chart screenshot first.');
      return;
    }

    if (profile.credits < AppCatalog.analysisCost) {
      _showSnack('Not enough credits. Buy a pack or upgrade your plan.');
      setState(() => _selectedIndex = 1);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final analysis = await _analysisService.uploadAndAnalyze(
        bytes: _selectedImageBytes!,
        fileName: _selectedFileName!,
        mimeType: _selectedMimeType,
      );
      final dashboard = await _dashboardService.loadDashboard();
      if (!mounted) return;
      setState(() {
        _latestAnalysis = analysis;
        _dashboard = dashboard;
        _selectedIndex = 0;
      });
      _showSnack('Analysis saved and 10 credits deducted.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _checkout(CheckoutProduct product) async {
    setState(() => _isBusy = true);
    try {
      await _billingService.launchCheckout(product);
      _showSnack('Stripe Checkout opened in your browser.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapPrice'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: widget.themeMode == ThemeMode.dark
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF070707),
                                Color(0xFF221000),
                                Color(0xFF090909),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFFFFFBF7),
                                Color(0xFFFFECD4),
                                Color(0xFFF9F0E3),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                    ),
                  ),
                ),
                SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildBody(dashboard),
                  ),
                ),
                if (_isBusy)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withAlpha(120),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Buy Credits',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DashboardState dashboard) {
    switch (_selectedIndex) {
      case 1:
        return _buildBuyCredits(dashboard);
      case 2:
        return _buildAccount(dashboard);
      case 3:
        return _buildSettings(dashboard);
      default:
        return _buildDashboard(dashboard);
    }
  }

  Widget _buildDashboard(DashboardState dashboard) {
    final profile = dashboard.profile;
    final recent = dashboard.analyses;
    final latest = _latestAnalysis ?? (recent.isNotEmpty ? recent.first.result : null);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _HeroPanel(
            email: profile.email,
            credits: profile.credits,
            plan: profile.plan,
            subscription: dashboard.subscription,
          ),
          const SizedBox(height: 18),
          _buildUploadCard(profile),
          const SizedBox(height: 18),
          if (latest != null) _AnalysisPanel(analysis: latest),
          if (latest != null) const SizedBox(height: 18),
          Text(
            'Recent analyses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            _EmptyCard(
              title: 'No saved scans yet',
              subtitle: 'Upload your first chart screenshot and the result will appear here.',
            )
          else
            ...recent.map(_HistoryTile.new),
        ],
      ),
    );
  }

  Widget _buildUploadCard(UserProfile profile) {
    final canAnalyze = profile.credits >= AppCatalog.analysisCost;
    final preview = _selectedImageBytes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Upload & analyze',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                _Pill(
                  icon: Icons.bolt_rounded,
                  text: '${AppCatalog.analysisCost} credits / scan',
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropTarget(
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              onDragDone: _handleDrop,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isDragging ? AppTheme.accent : Theme.of(context).dividerColor,
                    width: _isDragging ? 1.5 : 1,
                  ),
                  color: AppTheme.accent.withAlpha(14),
                ),
                child: Column(
                  children: [
                    if (preview != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          preview,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: AppTheme.heroGradient,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            kIsWeb
                                ? 'Drop a chart screenshot here or pick a file.'
                                : 'Pick a trading screenshot from your gallery.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Choose screenshot'),
                        ),
                        OutlinedButton.icon(
                          onPressed: canAnalyze && preview != null && !_isBusy
                              ? _runAnalysis
                              : null,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(
                            canAnalyze ? 'Analyze now' : 'Need more credits',
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _selectedFileName!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyCredits(DashboardState dashboard) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text(
          'Plans',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Stripe Checkout handles subscriptions and one-time credit packs. Weekly refills are managed on the backend.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        ...AppCatalog.subscriptions.map(
          (plan) => _OfferCard(
            product: plan,
            onPressed: () => _checkout(plan),
            badge: dashboard.profile.plan == plan.id ? 'Current plan' : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'One-time credit packs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        ...AppCatalog.creditPacks.map(
          (pack) => _OfferCard(
            product: pack,
            onPressed: () => _checkout(pack),
          ),
        ),
      ],
    );
  }

  Widget _buildAccount(DashboardState dashboard) {
    final profile = dashboard.profile;
    final subscription = dashboard.subscription;
    final user = Supabase.instance.client.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Email', value: profile.email),
                _InfoRow(label: 'Credits', value: profile.credits.toString()),
                _InfoRow(label: 'Plan', value: profile.plan),
                _InfoRow(
                  label: 'Auth providers',
                  value: user?.appMetadata['providers']?.toString() ?? 'email',
                ),
                _InfoRow(
                  label: 'Member since',
                  value: DateFormat.yMMMd().format(profile.createdAt.toLocal()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Status',
                  value: subscription?.status ?? 'inactive',
                ),
                _InfoRow(
                  label: 'Current period end',
                  value: subscription?.currentPeriodEnd == null
                      ? 'n/a'
                      : DateFormat.yMMMd().format(
                          subscription!.currentPeriodEnd!.toLocal(),
                        ),
                ),
                _InfoRow(
                  label: 'Last refill',
                  value: subscription?.lastCreditRefillAt == null
                      ? 'n/a'
                      : DateFormat.yMMMd().format(
                          subscription!.lastCreditRefillAt!.toLocal(),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(DashboardState dashboard) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Card(
          child: SwitchListTile(
            value: !isDark,
            title: const Text('Light mode'),
            subtitle: const Text('Switch between the trading dark UI and a lighter workspace.'),
            onChanged: (value) {
              widget.onThemeModeChanged(value ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Runtime setup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Supabase auth', value: 'Enabled'),
                _InfoRow(label: 'Google OAuth', value: 'Handled by Supabase'),
                _InfoRow(label: 'OpenAI scanning', value: 'Supabase Edge Function'),
                _InfoRow(label: 'Stripe payments', value: 'Hosted Checkout'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.email,
    required this.credits,
    required this.plan,
    required this.subscription,
  });

  final String email;
  final int credits;
  final String plan;
  final SubscriptionInfo? subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trading dashboard',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(label: 'Credits', value: credits.toString()),
              _HeroMetric(label: 'Plan', value: plan),
              _HeroMetric(
                label: 'Status',
                value: subscription?.status ?? 'free',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({required this.analysis});

  final TradeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final confidence = analysis.confidenceScore.clamp(0, 100).toDouble();
    final riskColor = switch (analysis.riskLevel.toLowerCase()) {
      'high' => AppTheme.danger,
      'low' => AppTheme.success,
      _ => AppTheme.warning,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(
                  title: 'Sentiment',
                  value: analysis.marketSentiment,
                  color: analysis.marketSentiment.toLowerCase() == 'bullish'
                      ? AppTheme.success
                      : analysis.marketSentiment.toLowerCase() == 'bearish'
                          ? AppTheme.danger
                          : AppTheme.warning,
                ),
                _SummaryCard(
                  title: 'Risk',
                  value: analysis.riskLevel,
                  color: riskColor,
                ),
                _SummaryCard(
                  title: 'Confidence',
                  value: '${analysis.confidenceScore}%',
                  color: AppTheme.accent,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Risk', 'Setup', 'Confidence'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[value.toInt()]),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [BarChartRodData(toY: _riskScore(analysis.riskLevel), color: riskColor)],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [BarChartRodData(toY: (analysis.keySignals.length * 18).clamp(12, 100).toDouble(), color: AppTheme.accentSoft)],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [BarChartRodData(toY: confidence, color: AppTheme.accent)],
                    ),
                  ],
                  maxY: 100,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SectionBlock(title: 'What is happening?', body: analysis.whatIsHappening),
            _SectionBlock(title: 'When to BUY', body: analysis.whenToBuy),
            _SectionBlock(title: 'When to SELL', body: analysis.whenToSell),
            _SectionBlock(title: 'Why', body: analysis.reasoning),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...analysis.keySignals.map((signal) => _SignalChip(label: signal)),
                ...analysis.detectedIndicators.map(
                  (signal) => _SignalChip(label: signal, outlined: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _riskScore(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return 30;
      case 'high':
        return 85;
      default:
        return 60;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withAlpha(22),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label, this.outlined = false});

  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : AppTheme.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: outlined ? Theme.of(context).dividerColor : AppTheme.accent.withAlpha(44),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.product,
    required this.onPressed,
    this.badge,
  });

  final CheckoutProduct product;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 10),
                          _Pill(icon: Icons.check_circle_outline, text: badge!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(product.priceLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(product.description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onPressed,
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(this.record);

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withAlpha(20),
          child: const Icon(Icons.insights_rounded, color: AppTheme.accent),
        ),
        title: Text(
          record.result.marketSentiment,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Text(
          '${record.result.entrySuggestion}\n${DateFormat.yMMMd().add_jm().format(record.createdAt.toLocal())}',
        ),
        isThreeLine: true,
        trailing: Text('${record.result.confidenceScore}%'),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 34, color: AppTheme.accent),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.accent.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
