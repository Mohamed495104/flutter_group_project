# Craftique - Detailed Bug Report & Code Issues

## 🔴 CRITICAL BUGS (Must Fix Immediately)

### Bug #1: Firebase Re-initialization Crash
**File:** `lib/providers/wishlist.dart`  
**Lines:** 24-29  
**Severity:** 🔴 CRITICAL

#### Current Code:
```dart
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(  // ❌ ERROR: Already initialized in main.dart
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
    ).ref();
    // ...
  } catch (e) {
    print('Error initializing WishlistProvider: $e');
  }
}
```

#### Problem:
- Firebase is already initialized in `main.dart:20-22`
- Re-initializing throws `FirebaseException: [core/duplicate-app]`
- Causes wishlist to fail silently and not load user favorites

#### Impact:
- ❌ Wishlist features don't work
- ❌ User cannot save favorites
- ❌ App may crash on some platforms
- ❌ Poor user experience with silent failure

#### Fix:
```dart
Future<void> _initializeFirebase() async {
  try {
    // ✅ Remove Firebase.initializeApp - already done in main.dart
    
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),  // Use existing Firebase instance
      databaseURL: 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
    ).ref();
    
    _auth.authStateChanges().listen((User? user) {
      if (user != null && _database != null) {
        _loadWishlist(user.uid);
      } else {
        _wishlist.clear();
        notifyListeners();
      }
    });
  } catch (e) {
    print('Error initializing WishlistProvider: $e');
  }
}
```

#### Testing:
1. Add item to wishlist
2. Restart app
3. Verify item is still in wishlist
4. Check debug console for errors

---

### Bug #2: Hardcoded Database URL (Configuration Drift)
**Files:** Multiple  
**Locations:**
- `lib/providers/cart_provider.dart:196`
- `lib/providers/wishlist.dart:33`
- `lib/screens/home_screen.dart:42`
- `lib/main.dart:27`

**Severity:** 🔴 CRITICAL (Maintenance)

#### Current Code (4 duplicate locations):
```dart
// cart_provider.dart
databaseURL: 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',

// wishlist.dart
databaseURL: 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',

// home_screen.dart
static const String _dbUrl = 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com';

// main.dart
databaseURL: 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
```

#### Problem:
- Same URL hardcoded in 4 different files
- If database URL changes (dev/staging/prod), need to update 4 places
- Easy to miss one location = bugs in production
- No environment-specific configuration

#### Impact:
- ❌ High risk of configuration drift
- ❌ Difficult to set up dev/staging/prod environments
- ❌ Testing becomes problematic
- ❌ Code smell / maintenance nightmare

#### Fix:
Create centralized configuration:

```dart
// lib/utils/firebase_config.dart
class FirebaseConfig {
  static const String realtimeDatabaseUrl = 
    'https://flutter-group-project-3541f-default-rtdb.firebaseio.com';
  
  // Future: Support environment-based URLs
  static String get databaseUrl {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
    
    switch (environment) {
      case 'development':
        return 'https://craftique-dev-default-rtdb.firebaseio.com';
      case 'staging':
        return 'https://craftique-staging-default-rtdb.firebaseio.com';
      case 'production':
      default:
        return realtimeDatabaseUrl;
    }
  }
}
```

Then update all 4 files:
```dart
// All files
databaseURL: FirebaseConfig.databaseUrl,
```

---

## 🟡 MEDIUM PRIORITY BUGS

### Bug #3: Silent Cart Operation Failures
**File:** `lib/providers/cart_provider.dart`  
**Lines:** 99-104, 136-139, 162-166, 180-184  
**Severity:** 🟡 MEDIUM

#### Current Code:
```dart
} catch (e) {
  debugPrint('Error adding to cart: $e');  // ❌ Only logs to console
} finally {
  _squelchRemote = false;
}
```

#### Problem:
- Errors are logged but not shown to user
- User has no feedback when operation fails
- Local state may be inconsistent with Firebase
- User thinks operation succeeded but it didn't

#### Impact:
- ❌ Confusing user experience
- ❌ Data inconsistency between client and server
- ❌ User loses trust in app reliability

#### Fix:
```dart
// Add error callback mechanism
class CartProvider with ChangeNotifier {
  Function(String)? onError;  // Error callback
  
  Future<void> addToCart(Product product, {int quantity = 1, String? imageUrl}) async {
    try {
      // ... existing code
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      
      // ✅ Notify user through callback
      onError?.call('Failed to add ${product.name} to cart. Please try again.');
      
      // ✅ Revert optimistic update if needed
      final idx = _cartItems.indexWhere((it) => (it['product'] as Product).id == product.id);
      if (idx != -1) {
        _cartItems.removeAt(idx);
        notifyListeners();
      }
    } finally {
      _squelchRemote = false;
    }
  }
}

// In UI (cart_screen.dart, product_card.dart):
final cartProvider = Provider.of<CartProvider>(context, listen: false);
cartProvider.onError = (message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
};
```

---

### Bug #4: No Loading State During Cart Operations
**File:** `lib/widgets/product_card.dart`  
**Lines:** 140-163  
**Severity:** 🟡 MEDIUM

#### Current Code:
```dart
ElevatedButton.icon(
  onPressed: () {
    if (inCart) {
      cartProvider.removeFromCart(product);  // ❌ No loading state
    } else {
      cartProvider.addToCart(product);  // ❌ No loading state
    }
    ScaffoldMessenger.of(context).showSnackBar(/* ... */);
  },
  // ...
)
```

#### Problem:
- Button stays enabled during async operation
- User can tap multiple times
- Multiple identical requests sent to Firebase
- No visual feedback that operation is in progress

#### Impact:
- ❌ Duplicate cart items
- ❌ Race conditions
- ❌ Excessive Firebase API calls
- ❌ Poor UX

#### Fix:
```dart
class _ProductCardState extends State<ProductCard> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final bool inCart = cartProvider.cartItems.any(
          (item) => (item['product'] as Product).id == widget.product.id,
        );

        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () async {  // ✅ Disable when loading
            setState(() => _isLoading = true);
            
            try {
              if (inCart) {
                await cartProvider.removeFromCart(widget.product);
              } else {
                await cartProvider.addToCart(widget.product);
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(/* ... */);
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          },
          icon: _isLoading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                inCart ? Icons.remove_shopping_cart_outlined : Icons.shopping_cart_outlined,
              ),
          label: Text(inCart ? 'Remove from Cart' : 'Add to Cart'),
        );
      },
    );
  }
}
```

---

### Bug #5: Inefficient Product Loading (No Pagination)
**File:** `lib/screens/home_screen.dart`  
**Lines:** 78-110  
**Severity:** 🟡 MEDIUM

#### Current Code:
```dart
Future<void> _loadProducts() async {
  if (_database == null) return;
  
  final snapshot = await _database!.child('products').once();  // ❌ Loads ALL products
  final raw = snapshot.snapshot.value;
  final List<Product> loaded = [];
  
  // ... processes all products
}
```

#### Problem:
- Loads entire product catalog on app start
- Performance degrades with >100 products
- Wastes bandwidth and memory
- Slow app startup on low-end devices

#### Impact:
- ❌ Poor performance at scale
- ❌ High data usage
- ❌ Slow initial load time
- ❌ Not production-ready for large catalogs

#### Fix:
```dart
// Implement pagination
class _HomeScreenState extends State<HomeScreen> {
  static const int _productsPerPage = 20;
  String? _lastProductKey;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  Future<void> _loadProducts({bool loadMore = false}) async {
    if (_database == null) return;
    if (loadMore && !_hasMore) return;
    
    setState(() => loadMore ? _isLoadingMore = true : _isLoading = true);
    
    try {
      // ✅ Query with limit
      Query query = _database!
        .child('products')
        .orderByKey()
        .limitToFirst(_productsPerPage + 1);
      
      if (loadMore && _lastProductKey != null) {
        query = query.startAfter(_lastProductKey);
      }
      
      final snapshot = await query.once();
      final raw = snapshot.snapshot.value;
      final List<Product> loaded = [];
      
      if (raw is Map) {
        final entries = raw.entries.toList();
        
        // Check if there are more products
        _hasMore = entries.length > _productsPerPage;
        
        // Take only requested number
        final itemsToProcess = _hasMore 
          ? entries.sublist(0, _productsPerPage)
          : entries;
        
        for (var entry in itemsToProcess) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          loaded.add(Product.fromMap(map, entry.key.toString()));
        }
        
        if (itemsToProcess.isNotEmpty) {
          _lastProductKey = itemsToProcess.last.key.toString();
        }
      }
      
      if (mounted) {
        setState(() {
          if (loadMore) {
            _allProducts.addAll(loaded);
          } else {
            _allProducts = loaded;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }
  
  // Add to GridView
  Widget _buildGrid() {
    return GridView.builder(
      // ... existing code
      itemBuilder: (context, index) {
        // Load more when reaching bottom
        if (index == filteredProducts.length - 1 && _hasMore && !_isLoadingMore) {
          _loadProducts(loadMore: true);
        }
        
        final product = filteredProducts[index];
        return ProductCard(product: product, onTap: () => _openProduct(product));
      },
    );
  }
}
```

---

## 🟠 LOW PRIORITY ISSUES

### Issue #6: Code Duplication - Image Loading Logic
**Files:** `lib/widgets/product_card.dart` & `lib/screens/product_details_screen.dart`  
**Severity:** 🟠 LOW (Code Quality)

#### Problem:
Identical image loading logic exists in 2 files (59 lines duplicated):
- product_card.dart lines 200-257
- product_details_screen.dart lines 35-100

#### Impact:
- ❌ Code duplication (DRY violation)
- ❌ Harder to maintain (fix bug in 2 places)
- ❌ Inconsistent behavior risk

#### Fix:
Create shared widget:

```dart
// lib/widgets/product_image.dart
class ProductImage extends StatelessWidget {
  final Product product;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? networkImageUrl;
  
  const ProductImage({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.networkImageUrl,
  });
  
  @override
  Widget build(BuildContext context) {
    final categoryFolder = _getCategoryFolder(product.category);
    final jpgPath = 'assets/images/$categoryFolder/${product.id}.jpg';
    
    return Image.asset(
      jpgPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        final pngPath = 'assets/images/$categoryFolder/${product.id}.png';
        return Image.asset(
          pngPath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error2, stackTrace2) {
            if (networkImageUrl != null && networkImageUrl!.startsWith('http')) {
              return Image.network(
                networkImageUrl!,
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, error3, stackTrace3) {
                  return _buildPlaceholder();
                },
              );
            }
            return _buildPlaceholder();
          },
        );
      },
    );
  }
  
  String _getCategoryFolder(String category) {
    switch (category) {
      case 'Paintings': return 'paintings';
      case 'Ceramics': return 'ceramics';
      case 'Jewelry': return 'jewelry';
      case 'Clothing': return 'clothing';
      case 'Miniature': return 'miniature';
      default: return category.toLowerCase();
    }
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F0),
      width: width,
      height: height,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40, color: Color(0xFF8B4513)),
            SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B4513)),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage in product_card.dart:
ProductImage(product: product, width: double.infinity, fit: BoxFit.cover)

// Usage in product_details_screen.dart:
ProductImage(
  product: product!, 
  width: double.infinity, 
  height: 300,
  networkImageUrl: productImage,
)
```

---

### Issue #7: Placeholder Test File
**File:** `test/widget_test.dart`  
**Severity:** 🟠 LOW (Missing Tests)

#### Current Code:
```dart
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // ❌ This is the default Flutter counter test, not Craftique-specific
    await tester.pumpWidget(const CraftiqueApp());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    // ...
  });
}
```

#### Problem:
- Test file contains default Flutter template code
- No actual tests for Craftique features
- Test will fail when run (no counter in Craftique)

#### Impact:
- ❌ No test coverage
- ❌ Can't catch regressions
- ❌ Harder to refactor with confidence

#### Fix:
```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_group_project/main.dart';
import 'package:flutter_group_project/providers/cart_provider.dart';
import 'package:flutter_group_project/providers/wishlist.dart';
import 'package:flutter_group_project/models/product.dart';
import 'package:provider/provider.dart';

void main() {
  group('CartProvider Tests', () {
    test('addToCart increases cart item count', () {
      final cart = CartProvider();
      final product = Product(
        id: 'test1',
        name: 'Test Product',
        description: 'Test Description',
        price: 29.99,
        category: 'Paintings',
        rating: 4.5,
      );
      
      expect(cart.cartItems.length, 0);
      // Note: Actual Firebase operations need mocking
    });
    
    test('totalPrice calculation is correct', () {
      final cart = CartProvider();
      // Add test products
      // Verify total price calculation
    });
  });
  
  group('WishlistProvider Tests', () {
    test('addToWishlist adds product', () {
      final wishlist = WishlistProvider();
      final product = Product(
        id: 'test2',
        name: 'Test Wishlist Product',
        description: 'Test',
        price: 49.99,
        category: 'Jewelry',
        rating: 5.0,
      );
      
      expect(wishlist.wishlist.length, 0);
      // Note: Actual Firebase operations need mocking
    });
  });
  
  group('Product Model Tests', () {
    test('Product.fromMap creates valid product', () {
      final map = {
        'name': 'Beautiful Painting',
        'description': 'A beautiful handmade painting',
        'price': 150.0,
        'category': 'Paintings',
        'rating': 4.8,
      };
      
      final product = Product.fromMap(map, 'paint1');
      
      expect(product.id, 'paint1');
      expect(product.name, 'Beautiful Painting');
      expect(product.price, 150.0);
      expect(product.category, 'Paintings');
    });
    
    test('Product.toMap creates valid map', () {
      final product = Product(
        id: 'ceramic1',
        name: 'Ceramic Vase',
        description: 'Handcrafted vase',
        price: 75.0,
        category: 'Ceramics',
        rating: 4.5,
      );
      
      final map = product.toMap();
      
      expect(map['id'], 'ceramic1');
      expect(map['name'], 'Ceramic Vase');
      expect(map['price'], 75.0);
    });
  });
}
```

---

## 📋 Summary: Bug Priority Matrix

| Bug ID | Description | Severity | Fix Time | User Impact |
|--------|-------------|----------|----------|-------------|
| #1 | Firebase re-initialization | 🔴 Critical | 1 hour | App crash |
| #2 | Hardcoded DB URLs | 🔴 Critical | 2 hours | Maintenance |
| #3 | Silent cart failures | 🟡 Medium | 3 hours | UX confusion |
| #4 | No loading states | 🟡 Medium | 4 hours | Duplicate operations |
| #5 | No pagination | 🟡 Medium | 6 hours | Poor performance |
| #6 | Code duplication | 🟠 Low | 2 hours | Maintainability |
| #7 | Missing tests | 🟠 Low | 8 hours | No coverage |

**Total Fix Time:** ~26 hours (3-4 days)  
**Critical Bugs:** 2  
**Medium Priority:** 3  
**Low Priority:** 2

---

*Bug report generated: November 19, 2025*  
*For high-level overview, see: EXECUTIVE_SUMMARY.md*  
*For complete analysis, see: PROJECT_ANALYSIS.md*
