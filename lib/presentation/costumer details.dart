import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class customer_details extends StatefulWidget {
  final String customerId;
  final String customerName;

  const customer_details({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<customer_details> createState() => _customer_detailsState();
}

class _customer_detailsState extends State<customer_details> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> ledger = [];
  double totalGive = 0;
  double totalGet = 0;
  double balance = 0;

  @override
  void initState() {
    super.initState();
    fetchLedger();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  Future<void> fetchLedger() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    final String url = "http://account.galaxyex.xyz/v1/user/api//account/get-ledger/${widget.customerId}";
    try {
      final authKey = await getAuthToken();
      if (authKey == null) {
        setState(() {
          errorMsg = "No authentication token found. Please log in again.";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authkey": authKey,
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meta']?['status'] == true) {
          final ledgerData = data['data'] ?? [];
          double give = 0, get = 0;
          for (var entry in ledgerData) {
            give += (entry['credit'] ?? 0).toDouble();
            get += (entry['debit'] ?? 0).toDouble();
          }
          setState(() {
            ledger = ledgerData;
            totalGive = give;
            totalGet = get;
            balance = give - get;
            isLoading = false;
            errorMsg = null;
          });
        } else {
          setState(() {
            errorMsg = "Failed to fetch ledger data!";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Failed to fetch ledger: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Error fetching ledger: $e";
        isLoading = false;
      });
    }
  }

  String formatDateTime(String input) {
    try {
      final dt = DateTime.parse(input);
      return "${dt.day} ${_monthName(dt.month)} ${dt.year} ${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)} ${dt.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return input;
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
  String _monthName(int m) =>
      ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][m - 1];

  @override
  Widget build(BuildContext context) {
    final appBarHeight = 60.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          backgroundColor: const Color(0xFF265E85),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.customerName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 22),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top info bar
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 22, bottom: 12, left: 18, right: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("You Will Give", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      "₹${balance.toStringAsFixed(2)}",
                      style: const TextStyle(color: Color(0xFFD06C6C), fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 6,
            color: const Color(0xFF265E85),
          ),
          // Ledger entries
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMsg != null
                ? Center(child: Text(errorMsg!))
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, left: 6, right: 6),
                    itemCount: ledger.length,
                    itemBuilder: (context, index) {
                      final entry = ledger[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date and time
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatDateTime(entry["date"] ?? ""),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                    if ((entry["note"] ?? "").toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          entry["note"],
                                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Credit
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: entry['credit'] > 0 ? const Color(0xFFFBEDEB) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                                child: Text(
                                  "₹${(entry['credit'] ?? 0).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: entry['credit'] > 0 ? const Color(0xFFD06C6C) : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              // Debit
                              Container(
                                decoration: BoxDecoration(
                                  color: entry['debit'] > 0 ? const Color(0xFFF8FAF5) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                                child: Text(
                                  "₹${(entry['debit'] ?? 0).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: entry['debit'] > 0 ? const Color(0xFF59844A) : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom buttons
                Container(
                  margin: const EdgeInsets.only(bottom: 20, top: 10, left: 20, right: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD06C6C),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            "You Give",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF59844A),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            "You Get",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}