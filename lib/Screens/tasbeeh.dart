import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  final List<Map<String, dynamic>> _defaultZikrList = [
    {
      'name': 'SubhanAllah',
      'arabic': 'سُبْحَانَ اللّٰه',
      'target': 33,
    },
    {
      'name': 'Alhamdulillah',
      'arabic': 'الْـحَمْـدُ للهِ',
      'target': 33,
    },
    {
      'name': 'Allahu Akbar',
      'arabic': 'اللّٰهُ أَكْبَر',
      'target': 34,
    },
    {
      'name': 'La ilaha illallah',
      'arabic': 'لَا إِلٰهَ إِلَّا اللّٰه',
      'target': 100,
    },
    {
      'name': 'Astaghfirullah',
      'arabic': 'أَسْتَغْفِرُ اللّٰه',
      'target': 100,
    },
  ];

  List<Map<String, dynamic>> _zikrList = [];
  int _selectedZikrIndex = 0;
  bool _isLoaded = false;

  // Per-zikr state
  List<int> _counts = [];
  List<int> _targets = [];
  List<int> _loops = [];

  // User option: tap only green circle or full screen (excluding app bar & zikr list)
  bool _tapAnywhere = false;

  @override
  void initState() {
    super.initState();
    _initializeZikrStates();
    _loadUserTapOption();
  }

  Future<void> _loadUserTapOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tapAnywhere = prefs.getBool('tasbeeh_tap_anywhere') ?? false;
    });
  }

  Future<void> _saveUserTapOption(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tasbeeh_tap_anywhere', value);
  }

  Future<void> _initializeZikrStates() async {
    final prefs = await SharedPreferences.getInstance();
    String? zikrJson = prefs.getString('zikr_list');
    if (zikrJson != null) {
      final decoded = jsonDecode(zikrJson);
      _zikrList = List<Map<String, dynamic>>.from(decoded);
    } else {
      _zikrList = List<Map<String, dynamic>>.from(_defaultZikrList);
    }

    List<int> counts = [];
    List<int> targets = [];
    List<int> loops = [];
    for (int i = 0; i < _zikrList.length; i++) {
      counts.add(prefs.getInt('zikr_count_$i') ?? 0);
      targets.add(prefs.getInt('zikr_target_$i') ?? (_zikrList[i]['target'] ?? 33));
      loops.add(prefs.getInt('zikr_loop_$i') ?? 1);
    }
    int selectedIndex = prefs.getInt('tasbeehZikrIndex') ?? 0;
    if (selectedIndex < 0 || selectedIndex >= _zikrList.length) selectedIndex = 0;
    setState(() {
      _counts = counts;
      _targets = targets;
      _loops = loops;
      _selectedZikrIndex = selectedIndex;
      _isLoaded = true;
    });
  }

  Future<void> _saveZikrState(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikr_count_$index', _counts[index]);
    await prefs.setInt('zikr_target_$index', _targets[index]);
    await prefs.setInt('zikr_loop_$index', _loops[index]);
    await prefs.setInt('tasbeehZikrIndex', _selectedZikrIndex);
  }

  Future<void> _saveFullZikrList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('zikr_list', jsonEncode(_zikrList));
  }

  void _incrementTasbeeh() async {
    if (!_isReady()) return;
    int idx = _selectedZikrIndex;
    int newCount = _counts[idx] + 1;
    int newLoop = _loops[idx];
    if (newCount >= _targets[idx]) {
      newCount = 0;
      newLoop++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tasbeeh loop $newLoop started!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    setState(() {
      _counts[idx] = newCount;
      _loops[idx] = newLoop;
    });
    await _saveZikrState(idx);
  }

  void _showSetTargetDialog() {
    int idx = _selectedZikrIndex;
    TextEditingController controller =
    TextEditingController(text: _targets[idx].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Target for ${_zikrList[idx]['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Enter Tasbeeh Target'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              int? newTarget = int.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                setState(() {
                  _targets[idx] = newTarget;
                  _counts[idx] = 0;
                  _loops[idx] = 1;
                  _zikrList[idx]['target'] = newTarget;
                });
                await _saveZikrState(idx);
                await _saveFullZikrList();
                Navigator.of(context).pop();
              }
            },
            child: Text('Set'),
          ),
        ],
      ),
    );
  }

  void _resetTasbeeh() async {
    int idx = _selectedZikrIndex;
    setState(() {
      _counts[idx] = 0;
      _loops[idx] = 1;
    });
    await _saveZikrState(idx);
  }

  void _onZikrSelected(int index) async {
    setState(() {
      _selectedZikrIndex = index;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeehZikrIndex', index);
  }


  void _showAddZikrDialog() {
    final _nameController = TextEditingController();
    final _targetController = TextEditingController(text: "33");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Zikr'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Target Count'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String name = _nameController.text.trim();
              int? target = int.tryParse(_targetController.text.trim());
              if (name.isNotEmpty && target != null && target > 0) {
                setState(() {
                  _zikrList.add({
                    'name': name,
                    'target': target,
                  });
                  _counts.add(0);
                  _targets.add(target);
                  _loops.add(1);
                  _selectedZikrIndex = _zikrList.length - 1;
                });
                await _saveFullZikrList();
                await _saveZikrState(_selectedZikrIndex);
                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
          )
        ],
      ),
    );
  }

  void _showDeleteZikrDialog(int idx) {
    final isDefault = idx < _defaultZikrList.length;
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default zikr cannot be deleted!'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete this zikr?'),
        content: Text(
          'Are you sure you want to delete "${_zikrList[idx]['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _zikrList.removeAt(idx);
                _counts.removeAt(idx);
                _targets.removeAt(idx);
                _loops.removeAt(idx);
                if (_selectedZikrIndex > idx) {
                  _selectedZikrIndex--;
                } else if (_selectedZikrIndex == idx) {
                  _selectedZikrIndex = 0;
                }
              });
              await _saveFullZikrList();
              await _saveZikrState(_selectedZikrIndex);
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.delete),
            label: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          )
        ],
      ),
    );
  }

  bool _isReady() {
    int n = _zikrList.length;
    return _isLoaded &&
        _counts.length == n &&
        _targets.length == n &&
        _loops.length == n &&
        _selectedZikrIndex >= 0 &&
        _selectedZikrIndex < n;
  }

  // Helper for tap detection: only count tap if not in appbar or zikr list
  Widget _buildTapLayer({required Widget child}) {
    if (!_tapAnywhere) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final local = renderBox.globalToLocal(details.globalPosition);
            if (local.dy < MediaQuery.of(context).padding.top + kToolbarHeight) return;
            final zikrListTop = constraints.maxHeight - 56 - 20;
            if (local.dy > zikrListTop) return;
            _incrementTasbeeh();
          },
          child: child,
        );
      },
    );
  }

  void _showTapOptionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Tasbeeh Tap Option"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              value: false,
              groupValue: _tapAnywhere,
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _tapAnywhere = val);
                  await _saveUserTapOption(val);
                  Navigator.of(context).pop();
                }
              },
              title: Text("Only tap on green circle"),
            ),
            RadioListTile<bool>(
              value: true,
              groupValue: _tapAnywhere,
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _tapAnywhere = val);
                  await _saveUserTapOption(val);
                  Navigator.of(context).pop();
                }
              },
              title: Text("Tap anywhere on screen"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady()) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final int idx = _selectedZikrIndex;
    final zikr = _zikrList[idx];
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tasbeeh',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.touch_app, color: Colors.white),
            tooltip: "Tap Option",
            onPressed: _showTapOptionDialog,
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            tooltip: "Add Zikr",
            onPressed: _showAddZikrDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: "Reset Tasbeeh",
            onPressed: _resetTasbeeh,
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            tooltip: "Edit Count",
            onPressed: _showSetTargetDialog,
          ),
        ],
      ),
      body: _buildTapLayer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 68.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 36),
                  // Main Tasbeeh Card
                  Card(
                    color: Colors.white.withOpacity(0.97),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32.0, horizontal: 80.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            zikr['arabic'] ?? zikr['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontFamily: 'Scheherazade',
                              color: Colors.teal[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (zikr['arabic'] != null)
                            SizedBox(height: 8),
                          if (zikr['arabic'] != null)
                            Text(
                              zikr['name'],
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.teal[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          SizedBox(height: 18),
                          Text(
                            'Target',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.teal[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${_targets[idx]}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Current Count',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.teal[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${_counts[idx]}',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                          ),
                          SizedBox(height: 17),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              'Loop: ${_loops[idx]}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 35),
                  GestureDetector(
                    onTap: _incrementTasbeeh,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.teal, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${_counts[idx]}',
                          style: TextStyle(
                            fontSize: 44,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    _tapAnywhere
                        ? 'Tap anywhere on screen to count Tasbeeh!'
                        : 'Tap the green circle to count Tasbeeh!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 15),
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _zikrList.length,
                        separatorBuilder: (_, __) => SizedBox(width: 9),
                        itemBuilder: (context, idx2) {
                          final z = _zikrList[idx2];
                          final isSelected = idx2 == _selectedZikrIndex;
                          return GestureDetector(
                            onLongPress: () {
                              _showDeleteZikrDialog(idx2);
                            },
                            child: ChoiceChip(
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    z['arabic'] ?? z['name'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'Scheherazade',
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.teal[800],
                                    ),
                                  ),
                                  if (z['arabic'] != null)
                                    SizedBox(height: 2),
                                  if (z['arabic'] != null)
                                    Text(
                                      z['name'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.teal[900],
                                      ),
                                    ),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: Colors.teal[700],
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              onSelected: (_) => _onZikrSelected(idx2),
                            ),
                          );
                        },
                      ),
                    ),
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