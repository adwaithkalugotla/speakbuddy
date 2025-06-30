import 'package:flutter/material.dart';

class SpeakerInfoScreen extends StatefulWidget {
  final Function(String, String, String, String, String) onContinue;

  final String? initialSpeaker1;
  final String? initialSpeaker2;
  final String? initialTopic;
  final String? initialFormat;
  final String mode;

  const SpeakerInfoScreen({
    super.key,
    required this.onContinue,
    required this.mode,
    this.initialSpeaker1,
    this.initialSpeaker2,
    this.initialTopic,
    this.initialFormat,
  });

  @override
  State<SpeakerInfoScreen> createState() => _SpeakerInfoScreenState();
}

class _SpeakerInfoScreenState extends State<SpeakerInfoScreen> with TickerProviderStateMixin {
  late TextEditingController _speaker1Controller;
  late TextEditingController _speaker2Controller;
  late TextEditingController _topicController;

  final _formKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedFormat = 'lincoln_douglas';

  final Map<String, String> _formatNames = {
    'lincoln_douglas': 'Lincoln-Douglas',
    'policy': 'Policy Debate',
    'public_forum': 'Public Forum',
    'casual': 'Casual Mode',
  };

  @override
  void initState() {
    super.initState();

    _speaker1Controller = TextEditingController(text: widget.initialSpeaker1 ?? "");
    _speaker2Controller = TextEditingController(text: widget.initialSpeaker2 ?? "");
    _topicController = TextEditingController(text: widget.initialTopic ?? "");
    _selectedFormat = widget.initialFormat ?? 'lincoln_douglas';

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward(); // start animation
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _speaker1Controller.dispose();
    _speaker2Controller.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Future.microtask(() {
        widget.onContinue(
          _speaker1Controller.text.trim(),
          _speaker2Controller.text.trim(),
          _topicController.text.trim(),
          _selectedFormat,
          widget.mode,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "🎤 Welcome to SpeakBuddy",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let’s set up your debate.",
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      _buildInputField(_speaker1Controller, "Speaker 1 Name", Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildInputField(_speaker2Controller, "Speaker 2 Name", Icons.person),
                      const SizedBox(height: 20),
                      _buildInputField(_topicController, "Debate Topic", Icons.topic_outlined),
                      const SizedBox(height: 20),

                      // ✅ Debate Format Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedFormat,
                        dropdownColor: Colors.black87,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          prefixIcon: const Icon(Icons.style, color: Colors.white),
                          labelText: "Debate Format",
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _formatNames.entries
                            .map((entry) => DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFormat = value!;
                          });
                        },
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.arrow_forward_ios),
                          label: const Text("Continue"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required";
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        suffixIcon: controller.text.trim().isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.greenAccent)
            : const Icon(Icons.error_outline, color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
