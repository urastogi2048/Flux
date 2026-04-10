import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_app/providers/auth_provider.dart';
import 'admin_setup_screen.dart';
import 'volunteer_setup_screen.dart';

class SignUpAs extends StatelessWidget {
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

     return Scaffold(
      backgroundColor: colorScheme.surface,
      body : SafeArea(
        child: Padding (
          padding: const EdgeInsets.only(left: 24.0, right:24.0, top: 100.0, bottom: 60.0),
          child : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children : [
        
              Text("Sign-Up as",
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color:colorScheme.onSurface,
              ),
              textAlign: TextAlign.left,
              ),
              const SizedBox(height : 150),
              FilledButton.icon(
                onPressed: () {  
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSetupScreen()));
                },
                icon: const Icon(Icons.business),
                label: const Text('NGO Admin'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {  
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerSetupScreen()));
                },
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Volunteer'),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                    
                      Navigator.pop(context); 
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),

            ]
          ),
        ),

      ),
     );
  }

}