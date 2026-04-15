import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing FarmFresh Connection...');
  const String baseUrl = 'http://localhost:8000';
  
  // 1. Test Root/Docs
  try {
    print('\n1️⃣ Testing Connection to Backend Root...');
    final response = await http.get(Uri.parse('$baseUrl/'));
    print('✅ Root Status: ${response.statusCode}');
  } catch (e) {
    print('❌ Root Connection Failed: $e');
  }

  // 2. Test Products List
  try {
    print('\n2️⃣ Testing GET /api/products/ ...');
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/'),
      headers: {'Accept': 'application/json'},
    );
    print('📥 Products Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Received ${data is List ? data.length : "unknown"} products');
      if (data is List && data.isNotEmpty) {
        print('📦 First product sample: ${data[0]["name"]}');
      }
    } else {
      print('❌ Products Fetch Failed: ${response.body}');
    }
  } catch (e) {
    print('❌ Products Request Failed: $e');
  }
}
