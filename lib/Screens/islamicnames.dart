import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_daily/Screens/topbar.dart'; // <-- Import the top bar widget

class IslamicNamesScreen extends StatefulWidget {
  @override
  _IslamicNamesScreenState createState() => _IslamicNamesScreenState();
}

class _IslamicNamesScreenState extends State<IslamicNamesScreen> {
  List<String> _maleNames = [];
  List<String> _femaleNames = [];
  List<String> _displayedNames = [];
  String _selectedGender = "Boy";
  String _search = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final maleJson = await rootBundle.loadString('assets/males_en.json');
      final femaleJson = await rootBundle.loadString('assets/females_en.json');

      final maleList = await compute(_parseJson, maleJson);
      final femaleList = await compute(_parseJson, femaleJson);

      if (mounted) {
        setState(() {
          _maleNames = maleList;
          _femaleNames = femaleList;
          _displayedNames = _maleNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading names: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static List<String> _parseJson(String jsonStr) {
    final data = jsonDecode(jsonStr);
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return e.values.first.toString();
        }
        return e.toString();
      }).toList();
    }
    return [];
  }

  void _onGenderChanged(String gender) {
    setState(() {
      _selectedGender = gender;
      _displayedNames = (gender == "Boy") ? _maleNames : _femaleNames;
      _search = "";
    });
  }

  List<String> _filterNames(String query) {
    if (query.isEmpty) return _displayedNames;
    return _displayedNames
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  String capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNames = _filterNames(_search);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(h * 0.13),
        child: IslamicTopBar(title: "Islamic Names"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- The top bar is now in the appBar property! ---

          // Search Field
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.025, w * 0.06, h * 0.013),
            child: Material(
              elevation: 1.5,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                style: GoogleFonts.poppins(fontSize: w * 0.041),
                decoration: InputDecoration(
                  hintText: "Search ${_selectedGender} Names..",
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFFB9C2D9),
                    fontSize: w * 0.040,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.teal[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 14),
                ),
                onChanged: (value) {
                  setState(() => _search = value);
                },
              ),
            ),
          ),

          // Gender Selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Boy button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onGenderChanged("Boy"),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedGender == "Boy"
                            ? const Color(0xFF18895B)
                            : const Color(0xFFE4E6EA),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedGender == "Boy"
                            ? [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.17),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Image.asset(
                              "assets/boy.png",
                              width: 25,
                              height: 25,
                            ),
                          ),
                          Text(
                            "Boy",
                            style: GoogleFonts.poppins(
                              color: _selectedGender == "Boy"
                                  ? Colors.white
                                  : const Color(0xFF18895B),
                              fontWeight: FontWeight.w600,
                              fontSize: w * 0.042,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.04),
                // Girl button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onGenderChanged("Girl"),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedGender == "Girl"
                            ? const Color(0xFF18895B)
                            : const Color(0xFFE4E6EA),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedGender == "Girl"
                            ? [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Image.asset(
                              "assets/girl.png",
                              width: 25,
                              height: 25,
                            ),
                          ),
                          Text(
                            "Girl",
                            style: GoogleFonts.poppins(
                              color: _selectedGender == "Girl"
                                  ? Colors.white
                                  : const Color(0xFF18895B),
                              fontWeight: FontWeight.w600,
                              fontSize: w * 0.042,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.0001),

          // Names List
          Expanded(
            child: filteredNames.isEmpty
                ? Center(
              child: Text(
                "No names found",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: w * 0.046,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : ListView.separated(
              itemCount: filteredNames.length,
              separatorBuilder: (_, __) => const Divider(
                color: Color(0xFF18895B),
                height: 1,
                thickness: 0.8,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final name = capitalize(filteredNames[index]);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.01),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFAED8C2),
                      radius: 21,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF18895B),
                          fontWeight: FontWeight.bold,
                          fontSize: w * 0.055,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: w * 0.045,
                        color: const Color(0xFF222B2F),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}