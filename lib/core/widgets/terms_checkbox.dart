import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';

/// "Acepto los términos y condiciones" checkbox. With [termsUrl] the words
/// "Términos y condiciones" become a link (with the link icon) that opens the
/// document inside the app, so the user knows it can be tapped.
class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? termsUrl;
  final Color? textColor;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.termsUrl,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.ink900;
    final url = termsUrl;
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (checked) => onChanged(checked ?? false),
          activeColor: AppColors.secondary500,
        ),
        Flexible(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              url == null ? 'Acepto los términos y condiciones' : 'Acepto los ',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ),
        if (url != null)
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => _TermsPage(url: url))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Términos y condiciones',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary500,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.secondary500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: AppColors.secondary500,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows the terms document inside the app.
class _TermsPage extends StatefulWidget {
  final String url;

  const _TermsPage({required this.url});

  @override
  State<_TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<_TermsPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y condiciones')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.secondary500),
            ),
        ],
      ),
    );
  }
}
