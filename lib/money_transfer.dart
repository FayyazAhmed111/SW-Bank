import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoneyTransfer extends StatefulWidget {
  const MoneyTransfer({super.key});

  @override
  _MoneyTransferState createState() => _MoneyTransferState();
}

class _MoneyTransferState extends State<MoneyTransfer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _balance = '0';
  String _errorMessage = '';
  String _confirmationMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    var user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _balance = doc['balance'].toString();
      });
    }
  }

  Future<void> _transferMoney() async {
    double currentBalance = double.tryParse(_balance) ?? 0;
    double transferAmount = double.tryParse(_amountController.text) ?? 0;

    if (transferAmount > currentBalance) {
      setState(() {
        _errorMessage = 'Insufficient balance.';
        _confirmationMessage = '';
      });
      return;
    }

    String receiverAccount = _accountNumberController.text;
    var receiverDoc = await _firestore
        .collection('users')
        .where('accountNumber', isEqualTo: receiverAccount)
        .limit(1)
        .get();

    if (receiverDoc.docs.isEmpty) {
      setState(() {
        _errorMessage = 'Receiver account not found.';
        _confirmationMessage = '';
      });
      return;
    }

    var receiverData = receiverDoc.docs.first;
    var receiverId = receiverData.id;
    double receiverBalance = receiverData['balance'];

    await _firestore.collection('users').doc(receiverId).update({
      'balance': receiverBalance + transferAmount,
    });

    var user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'balance': currentBalance - transferAmount,
      });
    }

    setState(() {
      _errorMessage = '';
      _confirmationMessage = 'Transfer successful to account: $receiverAccount';
      _fetchBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3A1C71),
                  Color(0xFFD76D77),
                  Color(0xFFFFAF7B)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            "Money Transfer",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Ensure this file exists in your assets folder
                    height: 100,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Balance: $_balance PKR",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Receiver Account Number',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007BFF),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007BFF),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  Text(
                    _confirmationMessage,
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _transferMoney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send Amount',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
