# Closet R11 — AI Outfit Suggestions

## Goal
Transform Closet from a passive wardrobe tracker into an active style advisor that helps users decide *what to wear today*.

---

## Features

### 1. "What to Wear Today" Card
- **Trigger:** Daily notification or home screen widget (iOS) / menu bar quick view (macOS)
- **Input:** Weather + calendar events + recent outfits
- **Output:** One outfit suggestion with item thumbnails + outfit name
- **Actions:** "Love it" → saves to outfit log, "Skip" → next suggestion

### 2. Weather-Aware Styling
- Fetch weather via wttr.in API (no key needed)
- Store last-fetched weather with each outfit log entry
- **Cold weather (<10°C):** Suggest layering, outerwear, warmer items
- **Hot weather (>25°C):** Suggest lighter items, avoid heavy layers
- **Rain:** Suggest waterproof/resistant items, layers

### 3. Occasion-Aware Suggestions
- Read iOS calendar events via EventKit (with permission)
- Detect event types: "meeting", "interview", "dinner", "workout", "date"
- Map event keywords to outfit categories:
  - "meeting/interview" → smart casual or formal
  - "dinner/date" → dressy, planned
  - "workout/gym" → athletic wear
  - "casual/weekend" → relaxed

### 4. Outfit Suggestion Algorithm
```
1. Get current weather + today's events
2. Determine target categories needed (top + bottom + shoes ≥ 1 each)
3. Filter wardrobe by weather appropriateness
4. Score items by:
   - Not worn in last 7 days (+10)
   - Matches event formality (+15)
   - Weather appropriate (+10)
   - Recently logged items avoid repetition (+5 off for each day since last worn)
5. Generate 3-5 outfit combinations
6. Sort by total score, return top 5
```

### 5. Taste Profile Integration
- Use style profile stats to guide suggestions:
  - High neutral ratio → stick to neutral palette
  - High fitted ratio → prefer slim-cut items
  - Top tags → match style keywords

---

## UI Changes

### iOS
- New "Today" tab between Wardrobe and Outfits
- Full-screen outfit suggestion card with swipe gestures
- Weather badge at top of Today screen

### macOS
- "What to Wear" section in menu bar popover
- Quick suggestion without opening full app

---

## Technical

### New Dependencies
- EventKit (system framework) for calendar access
- wttr.in for weather (no API key needed)

### New Services
- `WeatherService`: Fetch + cache weather data
- `CalendarService`: Read events from EventKit
- `SuggestionEngine`: AI-free rule-based suggestion engine

### Data Model Changes
- `Outfit.suggestedForWeather`: String? (weather at time of suggestion)
- `Outfit.suggestedForEvent`: String? (event type at time of suggestion)
- `WornEntry.weather`: String? (temperature + condition)

---

## Scope
- iOS + macOS
- Does NOT require CloudKit (offline-first approach)
- Calendar permission prompt shown on first launch
