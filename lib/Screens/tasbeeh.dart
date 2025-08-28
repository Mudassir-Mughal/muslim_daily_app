import 'package:flutter/material.dart';
import 'package:muslim_daily/Screens/topbar.dart';
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

  // User option: tap only button or full screen (excluding app bar & zikr card)
  bool _tapAnywhere = false;

  // For getting position of the "Tap the white button to count Tasbeeh!" text
  final GlobalKey _tapInstructionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeZikrStates();
    _loadUserTapOption();
  }

  Widget buildDialogHeader(String title, {Widget? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF18895B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (icon != null) icon,
        ],
      ),
    );
  }

  Widget dialogActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            minimumSize: Size(0, 44),
            elevation: 0,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
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
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildDialogHeader("Set Target for ${_zikrList[idx]['name']}"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Target Count:", style: TextStyle(fontWeight: FontWeight.w500)),
                  TextField(
                    controller: controller,
                    cursorColor: Color(0xFF18895B),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF18895B), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      dialogActionButton(
                        label: "Cancel",
                        color: Colors.green[200]!,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      dialogActionButton(
                        label: "Set",
                        color: Color(0xFF18895B),
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
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with solid green background, no image
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF18895B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              alignment: Alignment.centerLeft,
              child: Text(
                "Add New Zikr",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name:", style: TextStyle(fontWeight: FontWeight.w500)),
                  TextField(
                    controller: _nameController,
                    cursorColor: Color(0xFF18895B),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF18895B), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Target Count:", style: TextStyle(fontWeight: FontWeight.w500)),
                  TextField(
                    controller: _targetController,
                    cursorColor: Color(0xFF18895B),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF18895B), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              minimumSize: Size(0, 44),
                              elevation: 0,
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Add Button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF18895B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              minimumSize: Size(0, 44),
                              elevation: 0,
                            ),
                            child: Text(
                              "Add",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
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
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildDialogHeader("Delete Zikr"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete "${_zikrList[idx]['name']}"?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      dialogActionButton(
                        label: "Cancel",
                        color: Colors.green[200]!,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      dialogActionButton(
                        label: "Delete",
                        color: Color(0xFF18895B),
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

  bool _isReady() {
    int n = _zikrList.length;
    return _isLoaded &&
        _counts.length == n &&
        _targets.length == n &&
        _loops.length == n &&
        _selectedZikrIndex >= 0 &&
        _selectedZikrIndex < n;
  }

  // Tap layer: only increment when tap is "above" the instructional text
  Widget _buildTapLayer({required Widget child}) {
    if (!_tapAnywhere) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        // Find the instructional text position (below which taps should NOT increment)
        final renderBox = _tapInstructionKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final pos = renderBox.localToGlobal(Offset.zero);
          if (details.globalPosition.dy < pos.dy) {
            _incrementTasbeeh();
          }
        } else {
          // If not found, fallback to increment (should only rarely happen)
          _incrementTasbeeh();
        }
      },
      child: child,
    );
  }

  void _showTapOptionDialog() {
    bool tempTapAnywhere = _tapAnywhere;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildDialogHeader("Tasbeeh Tap Option"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<bool>(
                      value: false,
                      groupValue: tempTapAnywhere,
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => tempTapAnywhere = val);
                        }
                      },
                      title: Text("Only tap on button"),
                      activeColor: Color(0xFF18895B),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: tempTapAnywhere,
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => tempTapAnywhere = val);
                        }
                      },
                      title: Text("Tap anywhere on screen"),
                      activeColor: Color(0xFF18895B),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        dialogActionButton(
                          label: "Close",
                          color: Color(0xFF18895B),
                          onPressed: () async {
                            if (_tapAnywhere != tempTapAnywhere) {
                              setState(() => _tapAnywhere = tempTapAnywhere);
                              await _saveUserTapOption(tempTapAnywhere);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(85),
        child: IslamicTopBar(
          title: "Tasbeeh",
        ),
      ),
      body: _buildTapLayer(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 100.0, bottom: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon Buttons Row (under the top bar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.touch_app, color: Colors.green),
                        tooltip: "Tap Option",
                        onPressed: _showTapOptionDialog,
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        tooltip: "Add Zikr",
                        onPressed: _showAddZikrDialog,
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.green),
                        tooltip: "Reset Tasbeeh",
                        onPressed: _resetTasbeeh,
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green),
                        tooltip: "Edit Count",
                        onPressed: _showSetTargetDialog,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Zikr Card as in image2, with asset background, delete on long press
                GestureDetector(
                  onLongPress: () {
                    // Only allow delete for custom (non-default) zikr
                    bool isDefault = _selectedZikrIndex < _defaultZikrList.length;
                    if (!isDefault) {
                      _showDeleteZikrDialog(_selectedZikrIndex);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Zikr Card Image from assets (with rounded corners)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          "assets/zikrcard.png", // <-- your asset path
                          width: 350,
                          height: 200,

                        ),
                      ),
                      // Foreground: the actual card content with transparent background
                      Card(
                        elevation: 0,
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                          width: double.infinity,
                          child: Column(
                            children: [
                              // Arabic zikr
                              Center(
                                child: Text(
                                  zikr['arabic'] ?? '',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontFamily: 'Scheherazade',
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 6),
                              // Dashed divider
                              Container(
                                width: 120,
                                height: 2,
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Row(
                                      children: List.generate(
                                        18,
                                            (index) => Expanded(
                                          child: Container(
                                            color: index.isEven ? Colors.green : Colors.transparent,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 2),
                              // Transliteration (name) with arrows
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left, color: Colors.green, size: 30),
                                    onPressed: () {
                                      setState(() {
                                        _selectedZikrIndex = (_selectedZikrIndex - 1 + _zikrList.length) % _zikrList.length;
                                      });
                                    },
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      zikr['name'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right, color: Colors.green, size: 30),
                                    onPressed: () {
                                      setState(() {
                                        _selectedZikrIndex = (_selectedZikrIndex + 1) % _zikrList.length;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              // Target and Loop as green pills
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      "Target: ${_targets[idx]}",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      "Loop: ${_loops[idx]}",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Tasbeeh Device with Button and Counter (as in image1)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tasbeeh Black Icon Background
                    Image.asset(
                      'assets/tasbeehicon.png',
                      width: 250,
                      height: 180,
                      fit: BoxFit.contain,
                    ),

                    // Counter Display (rounded rect) - Positioned above center
                    Positioned(
                      top: 30, // Adjust position as needed
                      child: Container(
                        width: 100,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${_counts[idx]}',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // White Circular Button (pressable) - Centered
                    Positioned(
                      bottom: 32, // Adjust to fit inside the device circle
                      child: GestureDetector(
                        onTap: _incrementTasbeeh,
                        child: Container(
                          width: 100,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                // Instructional Text with key
                Text(
                  _tapAnywhere
                      ? 'Tap anywhere on the screen to count Tasbeeh!'
                      : 'Tap the white button to count Tasbeeh!',
                  key: _tapInstructionKey,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[900],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                // No zikr chips below!
              ],
            ),
          ),
        ),
      ),
    );
  }
}