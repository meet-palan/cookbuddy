import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cookbuddy/database/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class RecipeSellingPage extends StatefulWidget {
  final String currentUserEmail;

  RecipeSellingPage({required this.currentUserEmail});

  @override
  _RecipeSellingPageState createState() => _RecipeSellingPageState();
}

class _RecipeSellingPageState extends State<RecipeSellingPage> {
  List<Map<String, dynamic>> sellingRecipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSellingRecipes();
  }

  Future<void> _fetchSellingRecipes() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final recipes = await dbHelper.getSellingRecipes();
      setState(() {
        sellingRecipes = recipes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recipes: $e')),
      );
    }
  }

  void _buyRecipe(Map<String, dynamic> recipe) async {
    final dbHelper = DatabaseHelper.instance;
    try {
      final buyer = await dbHelper.getUserByEmail(widget.currentUserEmail);
      if (buyer == null) {
        throw Exception("Buyer not found.");
      }

      final buyerCredits = buyer['credits'] ?? 0;
      final recipeCredits = recipe['credits'] ?? 0;

      if (buyerCredits < recipeCredits) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient credits to buy this recipe.')),
        );
        return;
      }

      // Deduct credits
      final updatedCredits = buyerCredits - recipeCredits;
      await dbHelper.updateUserCredits(buyer['id'], updatedCredits);

      // Add transaction
      await dbHelper.addTransaction({
        'userId': buyer['id'],
        'credits': recipeCredits,
        'recipeId': recipe['id'],
      });

      // Validate recipe fields
      final recipeName = recipe['name']?.toString() ?? 'Untitled Recipe';
      final ingredients = recipe['ingredients']?.toString() ?? 'No ingredients provided.';
      final instructions = recipe['instructions']?.toString() ?? 'No instructions provided.';

      print('Recipe Data: name=$recipeName, ingredients=$ingredients, instructions=$instructions');

      // Load fonts
      final helvetica = pw.Font.ttf(await rootBundle.load('assets/fonts/Helvetica.ttf'));
      final helveticaBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Helvetica-Bold.ttf'));

      // Generate PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  recipeName,
                  style: pw.TextStyle(font: helveticaBold, fontSize: 24),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Ingredients:',
                  style: pw.TextStyle(font: helveticaBold, fontSize: 18),
                ),
                pw.Text(
                  ingredients,
                  style: pw.TextStyle(font: helvetica, fontSize: 14),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Instructions:',
                  style: pw.TextStyle(font: helveticaBold, fontSize: 18),
                ),
                pw.Text(
                  instructions,
                  style: pw.TextStyle(font: helvetica, fontSize: 14),
                ),
              ],
            );
          },
        ),
      );

      // Ask user to pick a custom directory
      String? outputDir = await FilePicker.platform.getDirectoryPath();

      if (outputDir == null || outputDir.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save operation was canceled.')),
        );
        return;
      }

      // Save PDF to the selected directory
      final filePath = '$outputDir/$recipeName.pdf';
      final file = File(filePath);
      final pdfBytes = await pdf.save();

      if (pdfBytes.isEmpty) {
        throw Exception('Generated PDF is empty.');
      }

      await file.writeAsBytes(pdfBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe "$recipeName" saved successfully at $filePath.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error purchasing recipe: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Market'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : sellingRecipes.isEmpty
          ? Center(
        child: Text(
          'No recipes available for sale.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: sellingRecipes.length,
        itemBuilder: (context, index) {
          final recipe = sellingRecipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final isCurrentUserRecipe = recipe['userEmail'] == widget.currentUserEmail;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: recipe['image'] != null
                  ? Image.memory(
                recipe['image'], // Assuming image is stored as BLOB
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            SizedBox(width: 12.0),
            // Recipe Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['name'] ?? 'No Name',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Listed by: ${recipe['listedBy'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Credits: ${recipe['credits'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Buy Button
            if (!isCurrentUserRecipe)
              ElevatedButton(
                onPressed: () => _buyRecipe(recipe),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text('BUY'),
              ),
          ],
        ),
      ),
    );
  }
}
