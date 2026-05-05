import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Center(child: PillIcon(size: 150)),
          ),
          const SizedBox(height: 32),
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                  text: 'MED',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                      letterSpacing: 1)),
              TextSpan(
                  text: 'CONTROL',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                      letterSpacing: 1)),
            ]),
          ),
          const SizedBox(height: 8),
          const Text(
            'SEU TRATAMENTO NO TEMPO CERTO',
            style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 13,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            color: Color(0xFF10B981),
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }
}
