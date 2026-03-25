# Closet — AI Personal Stylist

## 1. Concept & Vision

Closet is an AI-powered personal stylist that transforms a disorganized wardrobe into a curated, intelligent style system. Take a photo of any clothing item and the app instantly understands it — building a style graph of your entire wardrobe. Over time it learns your taste, senses the weather, and suggests outfits that feel *you*, not generic.

The experience feels like flipping through a high-end fashion editorial: unhurried, beautiful, and deeply personal.

---

## 2. Design Language

### Aesthetic Direction
Editorial minimalism meets fashion magazine. Think Celine lookbooks, The Row's web presence. White space is a feature. Typography carries weight.

### Color Palette
| Role | Name | Hex |
|------|------|-----|
| Background | Ivory | `#FAFAF8` |
| Surface | White | `#FFFFFF` |
| Primary Text | Charcoal | `#1C1C1E` |
| Secondary Text | Slate | `#6E6E73` |
| Accent | Warm Gold | `#B8A898` |
| Accent Alt | Sand | `#D4C5B5` |
| Divider | Mist | `#E8E8E6` |
| Error | Terracotta | `#C45C4A` |

### Typography
- **Headings:** New York (serif, Apple system) — editorial weight
- **Body / UI:** SF Pro (system sans-serif)
- **Captions / Tags:** SF Pro Light, tracked out
- Scale: 34pt hero → 22pt section → 17pt body → 13pt caption

### Spatial System
- Base unit: 8pt grid
- Card padding: 16pt
- Section spacing: 32pt
- Screen margins: 20pt
- Corner radius: 12pt cards, 8pt buttons

### Motion Philosophy
- Spring-based, 300–400ms for card transitions
- Swipe-to-dismiss on outfit cards (UISwipeGestureRecognizer via SwiftUI)
- Fade + scale on navigation pushes
- Haptic feedback on save/like actions

### Visual Assets
- SF Symbols for all icons (outfit, camera, grid, hanger)
- Clothing images: user-captured, displayed in rounded 12pt frames
- No stock photos — this is *your* wardrobe

---

## 3. Layout & Structure

### Tab Structure
```
┌─────────────────────────────────────────────┐
│  [Wardrobe]  [Outfits]  [Style Profile]      │
├─────────────────────────────────────────────┤
│                                             │
│              Tab Content                    │
│                                             │
└─────────────────────────────────────────────┘
```

**Tab 1 — Wardrobe:** Grid of clothing items, filterable by category. Camera FAB.
**Tab 2 — Outfits:** Outfit suggestion carousel + outfit log below.
**Tab 3 — Style Profile:** Taste profile cards, preference sliders.

### Responsive Strategy
- Portrait-primary (iPhone)
- iPad: 3–4 column grid, larger card sizes
- Adaptive spacing via GeometryReader

---

## 4. Features & Interactions

### 4.1 Wardrobe Capture
- **Trigger:** Floating camera button (bottom-right)
- **Flow:** Tap → ActionSheet (Camera / Photo Library) → PHPickerViewController → Vision detects clothing → Save to SQLite + local file storage
- **AI Detection:** VNClassifyImageRequest with `.garment` hierarchy + color extraction via CIAreaHistogram
- **Fallback:** If Vision returns no garment label, prompt user to manually set category
- **States:** Empty wardrobe (onboarding illustration) → Items flowing in

### 4.2 Wardrobe View
- **Layout:** 2-column LazyVGrid (portrait), 3-column (landscape/iPad)
- **Categories:** All, Tops, Bottoms, Shoes, Accessories, Outerwear
- **Category chip bar:** Horizontally scrollable pill buttons
- **Item card:** Square image, item name below, subtle shadow
- **Interactions:** Tap → Item detail sheet (image, category, color, tags, delete). Swipe left to delete.
- **Empty state:** Illustration + "Add your first piece" CTA

### 4.3 Outfit Generator
- **Input:** Weather (auto-fetch via wttr.in), Event type (dropdown: Casual, Work, Date, Sport, Formal), Mood (emoji picker: 😌 🏽 💪 🎉 🛋️)
- **Algorithm:** Rule-based matcher: category coverage (top+bottom+shoes ≥1 each), color harmony (neutral palette preferred unless mood=crazy), weather appropriateness (layers for cold)
- **Output:** Horizontal carousel of 5 outfit cards — each card shows 3 thumbnail images + outfit name
- **Swipe:** Left = not feeling it, Right = save to outfit log
- **Save:** Adds outfit snapshot to OutfitLog with timestamp

### 4.4 Outfit Log
- **List:** Chronological, most recent first. Each row: date, outfit thumbnail grid, event tag.
- **Detail:** Tap → full-screen outfit view with items listed
- **Delete:** Swipe left to delete

### 4.5 Style Profile
- **Taste dimensions tracked:**
  - Color preference: % Neutral (black/white/gray/beige) vs Colorful
  - Cut preference: Fitted vs Relaxed
  - Style tags: most frequent tags from saved outfits
  - Worn frequency: most/least worn items highlighted
- **Display:** Animated stat cards that update after each outfit log entry
- **Quote:** "You tend toward neutral tones and relaxed cuts. You saved 12 outfits this month."

---

## 5. Component Inventory

### ClothingItemCard
- Square image (1:1), 12pt corner radius
- Name label (SF Pro 13pt, Charcoal)
- Category pill (SF Pro 11pt, Sand background)
- States: default, loading (shimmer), error (placeholder icon)

### OutfitCard
- Horizontal scroll of 3 images (overlapping, -12pt offset each)
- Outfit name overlay at bottom (gradient scrim)
- Like/dislike buttons appear on first appearance, then swipe-only
- States: default, swiped-left (fade out), swiped-right (glow + save)

### CategoryChip
- Pill shape, 32pt height
- States: selected (Charcoal bg, White text), unselected (Mist bg, Slate text)

### StyleStatCard
- 120×160pt card, centered content
- Large number + unit (e.g., "73%")
- Subtitle (e.g., "Neutral Tones")
- Subtle animated bar fill on appear

### WeatherBadge
- Inline pill: icon (SF Symbol weather) + temperature
- Auto-refreshes on app foreground

---

## 6. Technical Approach

### Architecture
- **Pattern:** MVVM with Services layer
- **State:** @Observable (iOS 26 macro)
- **Navigation:** NavigationStack per tab

### Dependencies (Swift Package Manager)
| Package | Version | Purpose |
|---------|---------|---------|
| SQLite.swift | 0.15.3 | Local persistence |
| SnapKit | 5.7.1 | Auto Layout (if UIKit views needed) |

### Data Model
```
ClothingItem:
  - id: UUID
  - name: String
  - category: ClothingCategory (enum)
  - imagePath: String (local file URL relative)
  - dominantColors: [String] (hex)
  - tags: [String]
  - createdAt: Date
  - wearCount: Int

Outfit:
  - id: UUID
  - name: String
  - itemIds: [UUID]
  - eventType: EventType
  - mood: Mood
  - weather: String
  - createdAt: Date

StyleProfile:
  - neutralColorRatio: Double
  - fittedRatio: Double
  - topTags: [String:Int]
  - totalItems: Int
  - totalOutfits: Int
```

### Vision Integration
- `VNClassifyImageRequest` with `MLModel` trained/loaded for garment classification
- Fallback: `VNRecognizeTextRequest` on "color" field if manual entry
- Color extraction: CIAreaHistogram on downsampled image → dominant hue buckets

### CloudKit (Optional)
- CKContainer `iCloud.com.closet.stylist`
- CKRecord types: `ClothingItem`, `Outfit`, `StyleProfile`
- NSPersistentHistoryToken for sync
- User must opt-in; disabled by default

### Storage
- SQLite for metadata (all models)
- File system (app's Documents directory) for images
- Images named: `{UUID}.jpg`, compressed to 800px max dimension, JPEG 0.8 quality

### File Structure
```
Closet/
├── App/
│   └── ClosetApp.swift
├── Models/
│   ├── ClothingItem.swift
│   ├── Outfit.swift
│   ├── StyleProfile.swift
│   └── Enums.swift
├── Services/
│   ├── DatabaseService.swift
│   ├── VisionService.swift
│   ├── ImageStorageService.swift
│   ├── OutfitGeneratorService.swift
│   ├── WeatherService.swift
│   └── StyleProfileService.swift
├── ViewModels/
│   ├── WardrobeViewModel.swift
│   ├── OutfitViewModel.swift
│   └── StyleProfileViewModel.swift
├── Views/
│   ├── Components/
│   │   ├── ClothingItemCard.swift
│   │   ├── OutfitCard.swift
│   │   ├── CategoryChip.swift
│   │   ├── StyleStatCard.swift
│   │   └── WeatherBadge.swift
│   └── Screens/
│       ├── ContentView.swift
│       ├── WardrobeView.swift
│       ├── OutfitView.swift
│       ├── StyleProfileView.swift
│       ├── WardrobeCaptureView.swift
│       └── OutfitDetailView.swift
└── Resources/
    └── Assets.xcassets
```
