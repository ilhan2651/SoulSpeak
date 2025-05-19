import 'package:flutter/material.dart';
import '../base_scaffold.dart';

class HomePageHardHearing extends StatelessWidget {
  const HomePageHardHearing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 16),
                  child: Image.asset(
                    'assets/images/welcome.png',
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 40),
                    child: Image.asset(
                      'assets/images/ok.png',
                      width: 225,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
