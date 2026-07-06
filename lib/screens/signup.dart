import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, Supabase;

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool loading = false;
  bool acceptTerms = false;

  static const primary = Color(0xFFFF5A1F);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  double passwordStrength() {
    final password = passwordController.text.trim();
    double strength = 0;

    if (password.length >= 6) strength += .25;
    if (password.length >= 8) strength += .25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += .20;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += .15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength += .15;
    }

    return strength.clamp(0, 1);
  }

  String passwordStrengthText() {
    final value = passwordStrength();

    if (value == 0) return "";
    if (value < .4) return "Weak";
    if (value < .7) return "Medium";
    return "Strong";
  }

  Color passwordStrengthColor() {
    final value = passwordStrength();

    if (value < .4) return Colors.red;
    if (value < .7) return Colors.orange;
    return Colors.green;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool validateForm() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty) {
      showMessage("Please enter your full name");
      return false;
    }

    if (email.isEmpty || !isValidEmail(email)) {
      showMessage("Please enter a valid email");
      return false;
    }

    if (phone.isEmpty || !isValidPhone(phone)) {
      showMessage("Please enter valid 10 digit phone number");
      return false;
    }

    if (password.length < 6) {
      showMessage("Password must be at least 6 characters");
      return false;
    }

    if (password != confirmPassword) {
      showMessage("Password and confirm password do not match");
      return false;
    }

    if (!acceptTerms) {
      showMessage("Please accept Terms & Conditions");
      return false;
    }

    return true;
  }

  Future<void> signup() async {
  if (!validateForm()) return;

  try {
    if (mounted) {
      setState(() => loading = true);
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    final res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;

    if (user != null) {
      await supabase.from('users').upsert({
        'id': user.id,
        'name': name,
        'phone': phone,
        'email': email,
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account created successfully. Please login."),
      ),
    );

    Navigator.pop(context); // Back to Login Screen
  } on AuthException catch (e) {
    if (mounted) {
      showMessage(e.message);
    }
  } catch (e) {
    if (mounted) {
      showMessage("Signup Error: $e");
    }
  } finally {
    if (mounted) {
      setState(() => loading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength();
    final strengthText = passwordStrengthText();

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              heroSection(),
              const SizedBox(height: 20),
              signupCard(strength, strengthText),
              const SizedBox(height: 25),
              loginText(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget heroSection() {
    return SizedBox(
      height: 235,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: 10,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(.35),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 25,
            child: Image.network(
              "https://static.vecteezy.com/system/resources/thumbnails/023/390/201/small_2x/extreme-motor-bike-racer-illustration-mountain-biker-png.png",
              width: MediaQuery.of(context).size.width * .58,
              fit: BoxFit.contain,

              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return const SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5A1F)),
                  ),
                );
              },

              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.motorcycle,
                  color: Colors.white54,
                  size: 120,
                );
              },
            ),
          ),
          const Positioned(
            left: 0,
            top: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Account",
                  style: TextStyle(
                    color: primary,
                    fontSize: 43,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Start your smart riding journey",
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget signupCard(double strength, String strengthText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          premiumField(
            controller: nameController,
            label: "Full Name",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 15),

          premiumField(
            controller: emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),

          premiumField(
            controller: phoneController,
            label: "Phone Number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 15),

          premiumField(
            controller: passwordController,
            label: "Password",
            icon: Icons.lock_outline,
            obscure: obscurePassword,
            onChanged: (_) => setState(() {}),
            suffix: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(() => obscurePassword = !obscurePassword);
              },
            ),
          ),

          if (strengthText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(passwordStrengthColor()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  strengthText,
                  style: TextStyle(
                    color: passwordStrengthColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),

          premiumField(
            controller: confirmPasswordController,
            label: "Confirm Password",
            icon: Icons.lock_outline,
            obscure: obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(
                  () => obscureConfirmPassword = !obscureConfirmPassword,
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Checkbox(
                value: acceptTerms,
                activeColor: primary,
                onChanged: (value) {
                  setState(() {
                    acceptTerms = value ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  "I agree to the Terms & Conditions",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: loading ? null : signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: const [
              Expanded(child: Divider(color: Colors.white24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("OR", style: TextStyle(color: Colors.white54)),
              ),
              Expanded(child: Divider(color: Colors.white24)),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              socialButton(Icons.g_mobiledata),
              const SizedBox(width: 16),
              socialButton(Icons.facebook),
              const SizedBox(width: 16),
              socialButton(Icons.apple),
            ],
          ),
        ],
      ),
    );
  }

  Widget premiumField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1A2234),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget socialButton(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2234),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Widget loginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.white70),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            "Login",
            style: TextStyle(color: primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
