import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:lottie/lottie.dart'; 

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 Access Theme Data for Consistency
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark, 
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 🎥 ANIMATION / ICON
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: Lottie.asset(
                  'images/maintenance.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.construction_rounded,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 📝 TITLE
              Text(
                "Under Maintenance",
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, 
                ),
              ),

              const SizedBox(height: 16),

              // 📄 DESCRIPTION
              Text(
                "We are currently upgrading our systems to serve you better.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant, 
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // 🏠 HOME ACTION (No Firestore read)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text(
                    "Go to Home",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
