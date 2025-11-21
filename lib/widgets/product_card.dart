import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: true);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with wishlist button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildImage(),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (wishlistProvider.isInWishlist(widget.product)) {
                          wishlistProvider.removeFromWishlist(widget.product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from wishlist'),
                              backgroundColor: Color(0xFF8B4513),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          wishlistProvider.addToWishlist(widget.product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to wishlist'),
                              backgroundColor: Color(0xFF8B4513),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          wishlistProvider.isInWishlist(widget.product)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: wishlistProvider.isInWishlist(widget.product)
                              ? Colors.red
                              : const Color(0xFF8B4513),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${widget.product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const Spacer(),
                    // ✅ Toggle Add/Remove from Cart button (live)
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, _) {
                        // Set error handler
                        cartProvider.onError = (message) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        };
                        
                        final bool inCart = cartProvider.cartItems.any(
                          (item) =>
                              (item['product'] as Product).id == widget.product.id,
                        );

                        return SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () async {
                              setState(() => _isLoading = true);
                              
                              try {
                                if (inCart) {
                                  await cartProvider.removeFromCart(widget.product);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${widget.product.name} removed from cart'),
                                        backgroundColor: const Color(0xFF8B4513),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  await cartProvider.addToCart(widget.product);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('${widget.product.name} added to cart'),
                                        backgroundColor: const Color(0xFF8B4513),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                            icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  inCart
                                      ? Icons.remove_shopping_cart_outlined
                                      : Icons.shopping_cart_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                            label: Text(
                              _isLoading 
                                ? 'Processing...'
                                : (inCart ? 'Remove from Cart' : 'Add to Cart'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    String categoryFolder;

    switch (widget.product.category) {
      case 'Paintings':
        categoryFolder = 'paintings';
        break;
      case 'Ceramics':
        categoryFolder = 'ceramics';
        break;
      case 'Jewelry':
        categoryFolder = 'jewelry';
        break;
      case 'Clothing':
        categoryFolder = 'clothing';
        break;
      case 'Miniature':
        categoryFolder = 'miniature';
        break;
      default:
        categoryFolder = widget.product.category.toLowerCase();
    }

    final jpgPath = 'assets/images/$categoryFolder/${widget.product.id}.jpg';

    return Image.asset(
      jpgPath,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        final pngPath = 'assets/images/$categoryFolder/${widget.product.id}.png';
        return Image.asset(
          pngPath,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error2, stackTrace2) {
            return Container(
              color: const Color(0xFFF5F5F0),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 40, color: Color(0xFF8B4513)),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8B4513)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
