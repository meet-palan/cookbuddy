import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _userData;
  bool _isPasswordVisible = false;

  final TextEditingController _subscribeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _databaseHelper.getUserByEmail(widget.userEmail);
      if (user != null) {
        setState(() {
          _userData = user;
          _usernameController.text = user['username'] ?? '';
          _emailController.text = user['email'] ?? '';
          _passwordController.text = user['password'] ?? '';
        });
      }
    } catch (e) {
      _showSnackbar('Failed to fetch user data. Please try again later.');
    }
  }

  Future<void> _updateUserData() async {
    if (_userData != null) {
      final updatedUser = {
        'id': _userData!['id'],
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      };

      try {
        await _databaseHelper.updateUser(updatedUser);
        setState(() {
          _userData = updatedUser;
        });
        _showSnackbar('Profile updated successfully!');
      } catch (e) {
        _showSnackbar('Failed to update profile. Please try again.');
      }
    }
  }

  Future<void> _subscribeUser() async {
    final email = widget.userEmail;
    final message = _subscribeController.text.trim();

    if (message.isEmpty) {
      _showSnackbar('Please enter a message before subscribing.');
      return;
    }

    try {
      final isSubscribed = await _databaseHelper.isUserSubscribed(email);
      if (isSubscribed) {
        _showSnackbar('You are already subscribed. Thank you!');
      } else {
        await _databaseHelper.subscribeUser(email, message);
        _showSnackbar('Subscription successful. Thank you!');
      }
    } catch (e) {
      _showSnackbar('Failed to subscribe. Please try again later.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _userData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      (_userData?['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Greeting
                Center(
                  child: Text(
                    'Hello, ${_userData?['username'] ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Profile Card
                _buildCard(
                  child: Column(
                    children: [
                      _buildEditableField(
                        label: 'Username',
                        controller: _usernameController,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 10),
                      _buildEditableField(
                        label: 'Email',
                        controller: _emailController,
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: _updateUserData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Subscription Section
                _buildCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _subscribeController,
                        decoration: InputDecoration(
                          labelText: 'Subscribe',
                          hintText: 'Enter your message here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _subscribeUser,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                          child: const Text(
                            'Subscribe',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Card Widget
  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  // Editable Field Widget
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Password Field with Toggle Visibility
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
