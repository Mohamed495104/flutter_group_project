# Craftique Architecture Diagram

## 🏗️ Application Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CRAFTIQUE APP                             │
│                     (Flutter/Material 3)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Splash Screen│  │  Auth Screen │  │  Home Screen │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │Product Detail│  │ Cart Screen  │  │Wishlist Screen│         │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │Checkout Scr. │  │Confirmation  │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Uses
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        WIDGET LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ ProductCard  │  │CustomButton  │  │  InputField  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Consumes
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT LAYER                        │
│                       (Provider Pattern)                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────┐          │
│  │         CartProvider (ChangeNotifier)             │          │
│  ├───────────────────────────────────────────────────┤          │
│  │ • _cartItems: List<Map<String, dynamic>>         │          │
│  │ • addToCart(product, quantity, imageUrl)         │          │
│  │ • removeFromCart(product)                        │          │
│  │ • updateQuantity(product, quantity)              │          │
│  │ • clearCart()                                    │          │
│  │ • totalPrice (computed property)                 │          │
│  └───────────────────────────────────────────────────┘          │
│                                                                  │
│  ┌───────────────────────────────────────────────────┐          │
│  │       WishlistProvider (ChangeNotifier)           │          │
│  ├───────────────────────────────────────────────────┤          │
│  │ • _wishlist: List<Product>                       │          │
│  │ • addToWishlist(product)                         │          │
│  │ • removeFromWishlist(product)                    │          │
│  │ • isInWishlist(product): bool                    │          │
│  │ • clearWishlist()                                │          │
│  └───────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Interacts with
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         MODEL LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────┐          │
│  │                Product Model                      │          │
│  ├───────────────────────────────────────────────────┤          │
│  │ • id: String                                     │          │
│  │ • name: String                                   │          │
│  │ • description: String                            │          │
│  │ • price: double                                  │          │
│  │ • category: String                               │          │
│  │ • rating: double                                 │          │
│  │ • fromMap(map, id): Product                      │          │
│  │ • toMap(): Map<String, dynamic>                  │          │
│  └───────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Persists to
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND SERVICES LAYER                       │
│                        (Firebase BaaS)                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌─────────────────────┐              │
│  │  Firebase Auth      │  │ Firebase Realtime   │              │
│  │                     │  │     Database        │              │
│  ├─────────────────────┤  ├─────────────────────┤              │
│  │ • signIn()          │  │ • /products/        │              │
│  │ • signUp()          │  │ • /cart/{userId}/   │              │
│  │ • signOut()         │  │ • /users/{userId}/  │              │
│  │ • authStateChanges()│  │   wishlist/         │              │
│  └─────────────────────┘  └─────────────────────┘              │
│                                                                  │
│  ┌─────────────────────┐                                        │
│  │  Cloud Firestore    │                                        │
│  │  (Future use)       │                                        │
│  └─────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Data Flow Diagram

### User Adds Product to Cart:

```
User taps "Add to Cart" on ProductCard
            │
            ▼
┌───────────────────────────────────┐
│   ProductCard calls               │
│   cartProvider.addToCart()        │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   CartProvider:                   │
│   1. Update local state           │
│      (_cartItems.add())           │
│   2. Set _squelchRemote = true    │
│   3. notifyListeners()            │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   UI Updates Immediately          │
│   (Optimistic Update)             │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   CartProvider writes to Firebase │
│   Realtime Database:              │
│   /cart/{userId}/{cartItemId}     │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   Set _squelchRemote = false      │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   Firebase Stream Listener        │
│   (skipped due to squelch flag)   │
└───────────────────────────────────┘
```

### User Opens Cart Screen (Fresh Load):

```
User navigates to CartScreen
            │
            ▼
┌───────────────────────────────────┐
│   CartScreen builds with          │
│   Consumer<CartProvider>          │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   CartProvider already listening  │
│   to Firebase stream:             │
│   /cart/{userId}                  │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   Stream emits data event         │
│   (Firebase onValue listener)     │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   CartProvider:                   │
│   1. Clear local _cartItems       │
│   2. Parse Firebase data          │
│   3. Rebuild _cartItems list      │
│   4. notifyListeners()            │
└───────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│   Consumer rebuilds UI            │
│   Cart items displayed            │
└───────────────────────────────────┘
```

## 🔄 Navigation Flow

```
┌─────────────┐
│   Splash    │
│   Screen    │
└──────┬──────┘
       │ (auto-navigate after 2s)
       ▼
┌─────────────┐
│    Auth     │◄──────────────┐
│   Screen    │               │
└──────┬──────┘               │
       │ (on login success)   │ (on logout)
       ▼                      │
┌─────────────┐               │
│    Home     │───────────────┘
│   Screen    │
└──────┬──────┘
       │
       ├─────────────────┬──────────────┬──────────────┐
       │                 │              │              │
       ▼                 ▼              ▼              ▼
┌─────────────┐   ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Product    │   │   Cart   │  │ Wishlist │  │  Drawer  │
│  Details    │   │  Screen  │  │  Screen  │  │  (Menu)  │
└──────┬──────┘   └────┬─────┘  └──────────┘  └──────────┘
       │               │
       │               ▼
       │         ┌──────────┐
       │         │ Checkout │
       │         │  Screen  │
       │         └────┬─────┘
       │              │
       │              ▼
       │         ┌──────────┐
       │         │  Order   │
       │         │Confirma- │
       │         │  tion    │
       └─────────┴────┬─────┘
                      │ (navigate back to home)
                      ▼
                 ┌──────────┐
                 │   Home   │
                 │  Screen  │
                 └──────────┘
```

## 🗄️ Firebase Database Structure

```
firebase-realtime-database/
│
├── products/
│   ├── {productId}/
│   │   ├── id: String
│   │   ├── name: String
│   │   ├── description: String
│   │   ├── price: Number
│   │   ├── category: String
│   │   └── rating: Number
│   │
│   ├── paint1/
│   ├── paint2/
│   ├── ceramic1/
│   └── ...
│
├── cart/
│   └── {userId}/
│       └── {cartItemId}/
│           ├── productId: String
│           ├── productName: String
│           ├── categoryName: String
│           ├── imageUrl: String
│           ├── price: Number
│           ├── quantity: Number
│           ├── totalPrice: Number
│           └── timestamp: ServerValue.TIMESTAMP
│
└── users/
    └── {userId}/
        └── wishlist/
            └── [
                  {
                    id: String,
                    name: String,
                    description: String,
                    price: Number,
                    category: String,
                    rating: Number
                  },
                  ...
                ]
```

## 🎨 State Management Pattern

```
┌─────────────────────────────────────────────────────┐
│              MultiProvider (App Root)               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────────────┐   ┌──────────────────┐   │
│  │  WishlistProvider   │   │  CartProvider    │   │
│  │  (ChangeNotifier)   │   │  (ChangeNotifier)│   │
│  └─────────────────────┘   └──────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
                    │
                    │ Provides to entire widget tree
                    ▼
┌─────────────────────────────────────────────────────┐
│               Any Screen/Widget                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Consumer<CartProvider>(                           │
│    builder: (context, cartProvider, child) {       │
│      // Access cartProvider.cartItems              │
│      // Access cartProvider.totalPrice             │
│      // Call cartProvider.addToCart()              │
│    }                                               │
│  )                                                 │
│                                                     │
│  Consumer<WishlistProvider>(                       │
│    builder: (context, wishlistProvider, child) {   │
│      // Access wishlistProvider.wishlist           │
│      // Call wishlistProvider.addToWishlist()      │
│    }                                               │
│  )                                                 │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 📱 Screen Component Hierarchy

```
HomeScreen
│
├── AppBar
│   ├── Menu Icon (opens Drawer)
│   ├── Title ("Craftique")
│   ├── Wishlist Icon Badge (Consumer<WishlistProvider>)
│   └── Cart Icon Badge (Consumer<CartProvider>)
│
├── Drawer (Navigation)
│   ├── UserAccountsDrawerHeader
│   ├── Wishlist MenuItem
│   ├── Cart MenuItem
│   └── Logout MenuItem
│
└── Body (Column)
    ├── SearchBar (TextField)
    ├── Category Chips (Horizontal ListView)
    ├── Results Info (Conditional)
    └── Products Grid (GridView)
        └── ProductCard (Consumer<WishlistProvider & CartProvider>)
            ├── Product Image
            ├── Wishlist Button
            ├── Product Name
            ├── Price
            └── Add/Remove Cart Button
```

## 🔐 Authentication Flow

```
                    ┌─────────────┐
                    │  App Start  │
                    └──────┬──────┘
                           │
                           ▼
                  ┌────────────────┐
                  │  Auth Screen   │
                  └────────┬───────┘
                           │
                ┬──────────┴──────────┬
                │                     │
                ▼                     ▼
        ┌──────────────┐      ┌──────────────┐
        │    Login     │      │   Register   │
        │   (Email/    │      │   (Email/    │
        │   Password)  │      │   Password)  │
        └──────┬───────┘      └──────┬───────┘
               │                     │
               ▼                     ▼
        ┌─────────────────────────────────┐
        │  Firebase Authentication        │
        │  • Email/Password verification  │
        │  • Create user account          │
        │  • Generate auth token          │
        └─────────────┬───────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────┐
        │  authStateChanges() Stream      │
        │  • User signed in               │
        │  • CartProvider listens         │
        │  • WishlistProvider listens     │
        └─────────────┬───────────────────┘
                      │
                      ▼
               ┌─────────────┐
               │ Home Screen │
               └─────────────┘
```

---

## 💡 Key Architectural Decisions

### 1. **Provider for State Management**
**Why?** 
- Recommended by Flutter team
- Simple to understand and implement
- Efficient rebuilds with Consumer widgets
- Good for small to medium apps

**Alternatives considered:**
- Bloc (too complex for this scale)
- Riverpod (newer, less documentation)
- GetX (not recommended by Flutter team)

### 2. **Firebase Realtime Database (not Firestore)**
**Why?**
- Real-time synchronization out of the box
- Simple JSON-like data structure
- Good for cart (frequently updated data)
- Lower cost for small apps

**Trade-offs:**
- Less powerful querying than Firestore
- No offline persistence by default
- Limited scalability

### 3. **Named Routes with onGenerateRoute**
**Why?**
- Type-safe argument passing
- Centralized route logic
- Easy to maintain
- Deep linking support

### 4. **Asset-based Images with Network Fallback**
**Why?**
- Fast loading (bundled with app)
- Works offline
- Fallback to network if needed

**Trade-offs:**
- Larger app size
- Hard to update without app release

---

*Architecture documentation generated: November 19, 2025*
