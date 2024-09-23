import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semi-Ecommerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductListPage(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> products = [];
  List<dynamic> categories = [];
  String selectedCategory = '';
  String sortBy = 'asc';
  int limit = 10;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProducts();
  }

  Future<void> fetchCategories() async {
    final response = await http
        .get(Uri.parse('https://fakestoreapi.com/products/categories'));
    if (response.statusCode == 200) {
      setState(() {
        categories = json.decode(response.body);
      });
    }
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    String url = 'https://fakestoreapi.com/products?sort=$sortBy&limit=$limit';
    if (selectedCategory.isNotEmpty) {
      url = 'https://fakestoreapi.com/products/category/$selectedCategory';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
    fetchProducts();
  }

  void onSortChanged(String sort) {
    setState(() {
      sortBy = sort;
    });
    fetchProducts();
  }

  void onLimitChanged(int newLimit) {
    setState(() {
      limit = newLimit;
    });
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: sortBy,
              items: [
                DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                DropdownMenuItem(value: 'desc', child: Text('Descending')),
              ],
              onChanged: (value) => onSortChanged(value!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<int>(
              value: limit,
              items: [5, 10, 15, 25, 45, 75, 100]
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text('Limit $e')))
                  .toList(),
              onChanged: (value) => onLimitChanged(value!),
            ),
          ),
          isLoading
              ? CircularProgressIndicator()
              : Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => onCategorySelected(categories[index]),
                        child: Card(
                          child: Center(
                            child: Text(categories[index]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(products[index]['title']),
                        subtitle: Text('\$${products[index]['price']}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SingleProductPage(id: products[index]['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SingleProductPage extends StatelessWidget {
  final int id;

  SingleProductPage({required this.id});

  Future<Map<String, dynamic>> fetchProductDetails() async {
    final response =
        await http.get(Uri.parse('https://fakestoreapi.com/products/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchProductDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final product = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['title'],
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('\$${product['price']}',
                        style: TextStyle(fontSize: 20, color: Colors.green)),
                    SizedBox(height: 8),
                    Text(product['description']),
                    SizedBox(height: 16),
                    Image.network(product['image']),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
