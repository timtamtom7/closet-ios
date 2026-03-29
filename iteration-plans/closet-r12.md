# Closet R12 — Sharing & Collaboration

## Goal
Allow Closet users to share their wardrobe with partners, create shared closets for households, and maintain wish lists for future purchases.

---

## Features

### 1. Shared Closet with Partner
- **Invite flow:** Generate share link or QR code
- **Sync:** CloudKit private database for shared wardrobe
- **Permissions:** Both can add/remove items, view wear stats
- **Conflict resolution:** Last-write-wins for item updates, no deletions of partner's items without confirmation

### 2. Wish Lists
- New "Wish List" tab/section alongside wardrobe
- Add any clothing item (from your closet or external) to wish list
- Fields: name, category, estimated price, store/link, priority (low/medium/high)
- "Got it!" button moves item from wish list → wardrobe

### 3. Public Profile / Share Card
- Generate shareable outfit card image (Square, Instagram-ready)
- Include: outfit thumbnail grid + caption based on style profile stats
- Share to: Photos, Messages, Instagram Stories (UIActivityViewController)
- Optional: "Style Stats" card showing: items owned, outfits logged, top categories

### 4. Outfit Sharing
- Share individual outfits as cards
- Include: outfit preview, occasion tag, weather it was worn for
- Deep link back to app: `closet://outfit/{outfitId}`

---

## UI Changes

### iOS
- New "Wish List" tab (star icon)
- Share button on outfit detail view
- Shared closet toggle in settings

### macOS
- Wish list section in menu bar popover
- Share outfit button in outfit detail

---

## Technical

### CloudKit Integration
- **Container:** `iCloud.com.closet.stylist`
- **Record Types:**
  - `SharedCloset`: { ownerId, partnerId, createdAt }
  - `SharedClothingItem`: inherits ClothingItem + shared closet ref
  - `WishListItem`: { id, name, category, price, storeURL, priority, ownerId }
- **Subscriptions:** CKQuerySubscription for shared closet changes
- **User must opt-in** — sharing disabled by default

### Sharing Model
```
ClosetDataService:
  - localOnly: Bool (default true)
  - sharedClosetId: String? (CloudKit record ID)
  - wishList: [WishListItem]
```

### Deep Links
- Register `closet://` URL scheme
- Routes: `closet://outfit/{id}`, `closet://item/{id}`

---

## Privacy Considerations
- Explicit opt-in required for sharing
- Partner can be removed at any time (removes their access)
- Shared data stays in CloudKit private DB (not public)

---

## Scope
- iOS + macOS
- CloudKit required for sharing (no local fallback)
- Calendar/weather features from R11 still work offline
