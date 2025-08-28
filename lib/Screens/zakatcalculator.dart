import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_daily/Screens/bottomnavigator.dart';
import 'package:muslim_daily/Screens/topbar.dart'; // import your custom app bar

class ZakatCalculator extends StatelessWidget {
  const ZakatCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zakat Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.light(
          primary: Colors.green[800]!,
          secondary: Colors.green[400]!,
        ),
        useMaterial3: true,
      ),
      home: const ZakatCalculatorScreen(),
    );
  }
}

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController goldCtrl = TextEditingController();
  final TextEditingController silverCtrl = TextEditingController();
  final TextEditingController businessCtrl = TextEditingController();
  final TextEditingController investmentsCtrl = TextEditingController();
  final TextEditingController receivablesCtrl = TextEditingController();
  final TextEditingController liabilitiesCtrl = TextEditingController();
  final TextEditingController nisabCtrl = TextEditingController();

  double zakatAmount = 0.0;
  double netWealth = 0.0;
  double nisabValue = 160000.0; // default nisab
  String zakatMessage = "";
  bool calculated = false;

  void calculateZakat() {
    double cash = double.tryParse(cashCtrl.text.trim()) ?? 0.0;
    double gold = double.tryParse(goldCtrl.text.trim()) ?? 0.0;
    double silver = double.tryParse(silverCtrl.text.trim()) ?? 0.0;
    double business = double.tryParse(businessCtrl.text.trim()) ?? 0.0;
    double investments = double.tryParse(investmentsCtrl.text.trim()) ?? 0.0;
    double receivables = double.tryParse(receivablesCtrl.text.trim()) ?? 0.0;
    double liabilities = double.tryParse(liabilitiesCtrl.text.trim()) ?? 0.0;
    double nisab = double.tryParse(nisabCtrl.text.trim()) ?? 160000.0;

    setState(() {
      netWealth = cash + gold + silver + business + investments + receivables - liabilities;
      nisabValue = nisab;
      calculated = true;

      if (netWealth <= 0) {
        zakatAmount = 0.0;
        if (netWealth < 0) {
          zakatMessage =
          "Your liabilities exceed your assets. Zakat is not obligatory.";
        } else {
          zakatMessage =
          "Your net wealth is zero. Zakat is not due.";
        }
      } else if (netWealth < nisabValue) {
        zakatAmount = 0.0;
        zakatMessage =
        "Your net wealth is below the Nisab (${nisabValue.toStringAsFixed(2)} PKR). Zakat is not obligatory.";
      } else {
        zakatAmount = netWealth * 0.025;
        zakatMessage = "Zakat is obligatory and calculated below.";
      }
    });
  }

  Widget zakatField({
    required String label,
    required TextEditingController controller,
    required String assetIconPath,
    String? hint,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), // space above and below
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(fontSize: 13), // input text
        decoration: InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(assetIconPath, width: 16, height: 16, color: color ?? Colors.green[900]),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[900], fontWeight: FontWeight.w500)),
            ],
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13),
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poppins = GoogleFonts.poppins();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFc8e6c9),
        ),
        child: Column(
          children: [
            IslamicTopBar(
              title: "Zakat Calculator",
              onBack: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => MainScreen(initialIndex: 0),
                  ),
                      (route) => false,
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Assets Title (outside card)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        "Assets",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  zakatField(
                                    label: "Cash",
                                    controller: cashCtrl,
                                    assetIconPath: "assets/zakatcash.png",
                                    hint: "PKR",
                                  ),
                                  zakatField(
                                    label: "Silver Value",
                                    controller: silverCtrl,
                                    assetIconPath: "assets/zakatsilver.png",
                                    hint: "PKR",
                                  ),
                                  zakatField(
                                    label: "Investments",
                                    controller: investmentsCtrl,
                                    assetIconPath: "assets/zakatinvestment.png",
                                    hint: "PKR",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  zakatField(
                                    label: "Gold Value",
                                    controller: goldCtrl,
                                    assetIconPath: "assets/zakatgold.png",
                                    hint: "PKR",
                                  ),
                                  zakatField(
                                    label: "Business Assets",
                                    controller: businessCtrl,
                                    assetIconPath: "assets/zakatbusiness.png",
                                    hint: "PKR",
                                  ),
                                  zakatField(
                                    label: "Receivables",
                                    controller: receivablesCtrl,
                                    assetIconPath: "assets/zakatrecievable.png",
                                    hint: "PKR",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Liabilities & Nisab Title (outside card)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2, top: 6),
                      child: Text(
                        "Liabilities & Nisab",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: zakatField(
                                label: "Liabilities",
                                controller: liabilitiesCtrl,
                                assetIconPath: "assets/zakatliability.png",
                                hint: "PKR",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: zakatField(
                                label: "Nisab Value",
                                controller: nisabCtrl,
                                assetIconPath: "assets/zakatnisab.png",
                                hint: "160000",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Zakat Button & Result as before
                    ElevatedButton.icon(
                      onPressed: calculateZakat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF158443),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        minimumSize: const Size(0, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        shadowColor: const Color(0xFFA2C96F),
                      ),
                      icon: Icon(Icons.calculate, color: Colors.white, size: 30),  // Increased icon size
                      label: Text(
                        "Calculate Zakat",
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white), // Increased text size
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (calculated)
                      Card(
                        elevation: 5,
                        color: zakatAmount > 0 ? Colors.green[50] : Colors.red[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                zakatMessage,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: zakatAmount > 0 ? Colors.green[900] : Colors.red[800],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "Net Wealth: PKR ${netWealth.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "Nisab Used: PKR ${nisabValue.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              zakatAmount > 0
                                  ? Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 35),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Zakat Due: PKR ${zakatAmount.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                                  : Column(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 30),
                                  const SizedBox(height: 4),
                                  Text(
                                    "No Zakat is obligatory at this time.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}