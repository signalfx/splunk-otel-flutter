/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen demonstrating different ways to open web content
class BrowserLauncherScreen extends StatelessWidget {
  const BrowserLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browser Launch Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose how to open web content:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Custom Tabs (Android) / SFSafariViewController (iOS)
          _LaunchCard(
            title: 'In-App Browser',
            description:
                'Opens in Custom Tabs (Android) or Safari View Controller (iOS)',
            icon: Icons.web,
            color: Colors.blue,
            onTap: () => _launchInAppBrowser(context),
          ),
          const SizedBox(height: 12),

          // External Browser
          _LaunchCard(
            title: 'External Browser',
            description: 'Opens in the device\'s default browser app',
            icon: Icons.open_in_browser,
            color: Colors.green,
            onTap: () => _launchExternalBrowser(context),
          ),
          const SizedBox(height: 12),

          // WebView (already implemented)
          _LaunchCard(
            title: 'Embedded WebView',
            description: 'Opens in embedded WebView within the app',
            icon: Icons.web_asset,
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Use "Open WebView" button for embedded WebView',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchInAppBrowser(BuildContext context) async {
    final url = Uri.parse('https://www.splunk.com');
    try {
      // This uses Custom Tabs on Android and SFSafariViewController on iOS
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to launch: $e')));
      }
    }
  }

  Future<void> _launchExternalBrowser(BuildContext context) async {
    final url = Uri.parse('https://www.splunk.com');
    try {
      // This opens in the external browser app
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to launch: $e')));
      }
    }
  }
}

class _LaunchCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LaunchCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
