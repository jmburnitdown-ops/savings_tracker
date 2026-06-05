import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../providers/savings_provider.dart';

class MiniGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;
  const MiniGoalCard({super.key, required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context);
    bool isSelected = provider.selectedGoalId == goal.id;
    // Calculate progress with a clamp to ensure it doesn't exceed 1.0 visually
    final double displayProgress = goal.progress.clamp(0.0, 1.0);

    Uint8List? decodedBytes;
    if (goal.imageBase64 != null) {
      decodedBytes = base64Decode(goal.imageBase64!);
    }

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[800],
                  child: decodedBytes != null
                      ? Image.memory(decodedBytes, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${goal.currency}${goal.targetAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saved: ${goal.currency}${goal.currentSavings.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: displayProgress,
                      backgroundColor: Colors.grey[800],
                      // Logic: Turns green if goal is reached (>= 1.0)
                      color: displayProgress >= 1.0 ? Colors.greenAccent : Colors.redAccent,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                onPressed: () => provider.deleteGoal(goal.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SplitDetailsInspector extends StatefulWidget {
  final SavingsGoal goal;
  const SplitDetailsInspector({super.key, required this.goal});

  @override
  State<SplitDetailsInspector> createState() => _SplitDetailsInspectorState();
}

class _SplitDetailsInspectorState extends State<SplitDetailsInspector> {
  final _editNameController = TextEditingController();
  final _editTargetController = TextEditingController();
  final _depositController = TextEditingController();
  final _withdrawController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _editTargetDate;

  @override
  void initState() {
    super.initState();
    _editNameController.text = widget.goal.name;
    _editTargetController.text = widget.goal.targetAmount.toString();
    _editTargetDate = widget.goal.targetDate;
  }

  @override
  void didUpdateWidget(covariant SplitDetailsInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.id != widget.goal.id) {
      _editNameController.text = widget.goal.name;
      _editTargetController.text = widget.goal.targetAmount.toString();
      _editTargetDate = widget.goal.targetDate;
      _depositController.clear();
      _withdrawController.clear();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<FlSpot> _generateChartSpots() {
    if (widget.goal.ledgerHistory.isEmpty) return [const FlSpot(0, 0)];
    
    final reversedHistory = widget.goal.ledgerHistory.reversed.toList();
    List<FlSpot> spots = [const FlSpot(0, 0)];
    double rollingBalance = 0;

    for (int i = 0; i < reversedHistory.length; i++) {
      final tx = reversedHistory[i];
      if (tx.type == 'Deposit') {
        rollingBalance += tx.amount;
      } else {
        rollingBalance -= tx.amount;
        if (rollingBalance < 0) rollingBalance = 0;
      }
      spots.add(FlSpot((i + 1).toDouble(), rollingBalance));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context, listen: false);
    final spots = _generateChartSpots();

    return DefaultTabController(
      length: 2,
      child: Container(
        color: Colors.black45,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.goal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(widget.goal.isArchived ? Icons.unarchive : Icons.archive, color: Colors.redAccent, size: 18),
                      tooltip: widget.goal.isArchived ? 'Restore Goal' : 'Archive Goal to Vault',
                      onPressed: () {
                        provider.toggleArchiveGoal(widget.goal.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(widget.goal.isArchived ? 'Restored back to tracking!' : 'Safely stored in Vault! 🏆')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => provider.clearSelection(),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            const TabBar(
              indicatorColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.dashboard_customize), text: 'Dashboard'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Activity History'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    children: [
                      const Text("Savings Growth Trajectory", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Container(
                        height: 160,
                        padding: const EdgeInsets.only(right: 20, top: 10, bottom: 5),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.redAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.15)),
                              )
                            ]
                          )
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ... (Rest of existing UI elements below)
                      Card(
                        color: Colors.red.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm, color: Colors.redAccent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _editTargetDate == null 
                                          ? "No Timeline Assigned" 
                                          : "Deadline: ${_editTargetDate!.month}/${_editTargetDate!.day}/${_editTargetDate!.year}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(widget.goal.dynamicPaceAdvice, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    if (_editTargetDate != null && widget.goal.targetAmount > widget.goal.currentSavings) ...[
                                      const SizedBox(height: 6),
                                      Builder(
                                        builder: (context) {
                                          final daysRemaining = _editTargetDate!.difference(DateTime.now()).inDays;
                                          final remainingBalance = widget.goal.targetAmount - widget.goal.currentSavings;
                                          if (daysRemaining > 0) {
                                            final dailyRequired = remainingBalance / daysRemaining;
                                            return Text(
                                              "Required Velocity: ${widget.goal.currency}${dailyRequired.toStringAsFixed(2)} / day",
                                              style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                            );
                                          }
                                          return const Text("Target date reached!", style: TextStyle(fontSize: 11, color: Colors.redAccent));
                                        },
                                      ),
                                    ]
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.goal.unlockedMilestones.isNotEmpty) ...[
                        const Text("Unlocked Badges & Accomplishments", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.goal.unlockedMilestones.length,
                            itemBuilder: (context, index) {
                              final badge = widget.goal.unlockedMilestones[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.redAccent, width: 1)),
                                child: Row(
                                  children: [
                                    Text(badge['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text("- ${badge['desc']!}", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 24),
                      ],
                      TextField(controller: _editNameController, decoration: const InputDecoration(labelText: 'Goal Title Name', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _editTargetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Target Cap Limit (${widget.goal.currency})', border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), alignment: Alignment.centerLeft),
                        icon: const Icon(Icons.calendar_month, color: Colors.redAccent),
                        label: Text(_editTargetDate == null ? 'Set Financial Target Deadline' : 'Target Date: ${_editTargetDate!.month}/${_editTargetDate!.day}/${_editTargetDate!.year}'),
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: _editTargetDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2100));
                          if (picked != null) setState(() => _editTargetDate = picked);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          icon: const Icon(Icons.save, size: 16, color: Colors.white),
                          label: const Text('Save Form Updates', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            final name = _editNameController.text.trim();
                            final tgt = double.tryParse(_editTargetController.text) ?? 0.0;
                            if (name.isNotEmpty && tgt > 0) {
                              provider.updateGoalDetails(widget.goal.id, name, tgt, newTargetDate: _editTargetDate);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details saved successfully.')));
                            }
                          },
                        ),
                      ),
                      const Divider(height: 32),
                      const Text('Post Financial Transactions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [100, 500, 1000].map((amount) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: ActionChip(
                              backgroundColor: Colors.red.withOpacity(0.12),
                              side: const BorderSide(color: Colors.red),
                              label: Text("+${widget.goal.currency}$amount", style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                provider.addSavingsToGoal(widget.goal.id, amount.toDouble());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Quick deposited ${widget.goal.currency}$amount!'), duration: const Duration(milliseconds: 700)),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(controller: _depositController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Deposit Amount (${widget.goal.currency})', border: const OutlineInputBorder())),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              final val = double.tryParse(_depositController.text) ?? 0.0;
                              final desc = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
                              if (val > 0) {
                                provider.addSavingsToGoal(widget.goal.id, val, description: desc);
                                _depositController.clear();
                                _descriptionController.clear();
                              }
                            },
                            child: const Text('Deposit'),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(controller: _withdrawController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Withdraw Amount (${widget.goal.currency})', border: const OutlineInputBorder())),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                            onPressed: () {
                              final val = double.tryParse(_withdrawController.text) ?? 0.0;
                              final desc = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
                              if (val > 0) {
                                provider.withdrawFromGoal(widget.goal.id, val, description: desc);
                                _withdrawController.clear();
                                _descriptionController.clear();
                              }
                            },
                            child: const Text('Withdraw'),
                          )
                        ],
                      ),
                    ],
                  ),
                  // History Tab
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statement Activity History', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: widget.goal.ledgerHistory.isEmpty
                            ? const Center(child: Text('No transfers logged yet.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                            : ListView.builder(
                                itemCount: widget.goal.ledgerHistory.length,
                                itemBuilder: (context, idx) {
                                  final tx = widget.goal.ledgerHistory[idx];
                                  bool isDeposit = tx.type == 'Deposit';
                                  return Card(
                                    color: Colors.black26,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: isDeposit ? Colors.greenAccent : Colors.redAccent, size: 14),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tx.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                          if (tx.description != null && tx.description!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(tx.description!, style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text('${tx.timestamp.month}/${tx.timestamp.day} at ${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      trailing: Text(
                                        '${isDeposit ? "+" : "-"}${widget.goal.currency}${tx.amount.toStringAsFixed(0)}',
                                        style: TextStyle(color: isDeposit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateGoalDialog extends StatefulWidget {
  const CreateGoalDialog({super.key});

  @override
  State<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final List<String> _currencies = ['\$', '₱', '€', '£', '¥', '₩'];
  late String _selectedCurrency;
  Uint8List? _previewBytes;
  String? _base64String;
  bool _isSaving = false;
  DateTime? _selectedTargetDate;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _currencies[0]; 
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
    if (image != null) {
      final rawBytes = await image.readAsBytes();
      if (!mounted) return;

      final Uint8List? croppedBytes = await showDialog<Uint8List?>(
        context: context,
        builder: (context) => ManualCropDialog(imageBytes: rawBytes),
      );

      if (croppedBytes != null) {
        setState(() {
          _previewBytes = croppedBytes;
          _base64String = base64Encode(croppedBytes);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context, listen: false);
    return AlertDialog(
      title: const Text('Add Goal Saver'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Goal Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Row(
              children: [
                WidgetDropDownCurrency(
                  selectedCurrency: _selectedCurrency, 
                  currencies: _currencies,
                  onChanged: (val) { if (val != null) setState(() => _selectedCurrency = val); }
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: _targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount', border: OutlineInputBorder())),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
              icon: const Icon(Icons.date_range, color: Colors.redAccent),
              label: Text(_selectedTargetDate == null ? 'Set Target Deadline Date (Optional)' : 'Deadline: ${_selectedTargetDate!.month}/${_selectedTargetDate!.day}/${_selectedTargetDate!.year}'),
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (picked != null) setState(() => _selectedTargetDate = picked);
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.grey[800]),
                  child: _previewBytes != null
                      ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 24, color: Colors.grey),
                            Text('1:1 Picture', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isSaving ? null : () async {
            final name = _nameController.text.trim();
            final target = double.tryParse(_targetController.text) ?? 0.0;
            if (name.isNotEmpty && target > 0) {
              setState(() => _isSaving = true);
              await provider.addGoal(name, target, _selectedCurrency, _base64String, targetDate: _selectedTargetDate);
              if (mounted) Navigator.pop(context);
            }
          },
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class WidgetDropDownCurrency extends StatelessWidget {
  final String selectedCurrency;
  final List<String> currencies;
  final ValueChanged<String?> onChanged;
  const WidgetDropDownCurrency({super.key, required this.selectedCurrency, required this.currencies, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: DropdownButtonFormField<String>(
        value: selectedCurrency,
        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
        items: currencies.map((symbol) => DropdownMenuItem<String>(value: symbol, child: Text(symbol))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class ManualCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const ManualCropDialog({super.key, required this.imageBytes});

  @override
  State<ManualCropDialog> createState() => _ManualCropDialogState();
}

class _ManualCropDialogState extends State<ManualCropDialog> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Position & Scale (1:1)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 240,
              height: 240,
              color: Colors.black,
              child: GestureDetector(
                onPanUpdate: (details) => setState(() => _offset += details.delta),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: _offset,
                      child: Transform.scale(scale: _scale, child: Image.memory(widget.imageBytes, fit: BoxFit.contain)),
                    ),
                    Container(decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 2.5))),
                  ],
                ),
              ),
            ),
          ),
          Slider(
            value: _scale,
            min: 1.0,
            max: 4.0,
            activeColor: Colors.red,
            onChanged: (val) => setState(() => _scale = val),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, widget.imageBytes),
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
