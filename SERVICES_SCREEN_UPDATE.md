# Services Screen UI Update

## Changes Made

### 1. **Back Button** ✅
- Added back button to the app bar using `leading` parameter
- Clicking it navigates back using `context.pop()`
- Updated `CommonAppBar` widget to support `leading` parameter

### 2. **Expand/Collapse Categories** ✅
- Categories are now collapsible/expandable
- Click on category header to toggle expansion state
- Expand/collapse icon changes based on state (▲/▼)
- All categories start expanded by default
- State is tracked per category in `_expandedCategories` map

### 3. **Tab-like Layout with Wrap** ✅
- Changed from `GridView` to `Wrap` widget for better control
- Fixed card sizes:
  - **Mobile**: 2 items per row, calculated width = `(screen_width - 48) / 2`
  - **Desktop**: Fixed width of 160px per card
- Cards maintain consistent size across all screen sizes
- Proper spacing between cards (12px horizontal and vertical)

### 4. **Dynamic Total Calculation** ✅
- Total price now updates based on selected services
- Displays as "Total: $XXX.XX"
- Automatically recalculates when services are selected/deselected

## File Changes

### `lib/presentation/screens/pages/services_screen.dart`
- Added `_expandedCategories` map to track expansion state
- Updated `build()` method with back button and expand/collapse logic
- Created `_buildServicesGrid()` method using Wrap layout
- Created `_calculateTotal()` method for dynamic pricing
- Updated shimmer skeleton to match new layout

### `lib/shared/widgets/common_app_bar.dart`
- Added `leading` parameter to support custom leading widgets
- Maintains backward compatibility with existing code

## Layout Details

### Mobile (< 600px)
```
┌─────────────────────────────┐
│ ← Select Services           │
├─────────────────────────────┤
│ [Search bar]                │
│                             │
│ [Pet Grooming ▼]            │
│ ┌──────────┐ ┌──────────┐   │
│ │ Service1 │ │ Service2 │   │
│ │ 30 min   │ │ 45 min   │   │
│ │ $50      │ │ $75      │   │
│ └──────────┘ └──────────┘   │
│ ┌──────────┐ ┌──────────┐   │
│ │ Service3 │ │ Service4 │   │
│ │ 60 min   │ │ 30 min   │   │
│ │ $100     │ │ $60      │   │
│ └──────────┘ └──────────┘   │
│                             │
│ [Haircut ▼]                 │
│ ...                         │
├─────────────────────────────┤
│ Total: $215.00              │
│ 2 Services Selected         │
│ [Continue]                  │
└─────────────────────────────┘
```

### Desktop (≥ 600px)
```
┌──────────────────────────────────────────────────────┐
│ ← Select Services                                    │
├──────────────────────────────────────────────────────┤
│ [Search bar]                                         │
│                                                      │
│ [Pet Grooming ▼]                                     │
│ ┌──────┐ ┌──────┐ ┌──────┐                           │
│ │Svc 1 │ │Svc 2 │ │Svc 3 │                           │
│ │30min │ │45min │ │60min │                           │
│ │$50   │ │$75   │ │$100  │                           │
│ └──────┘ └──────┘ └──────┘                           │
│ ┌──────┐ ┌──────┐ ┌──────┐                           │
│ │Svc 4 │ │Svc 5 │ │Svc 6 │                           │
│ │30min │ │45min │ │60min │                           │
│ │$60   │ │$80   │ │$90   │                           │
│ └──────┘ └──────┘ └──────┘                           │
│                                                      │
│ [Haircut ▼]                                          │
│ ...                                                  │
├──────────────────────────────────────────────────────┤
│ Total: $215.00                                       │
│ 2 Services Selected                                  │
│ [Continue]                                           │
└──────────────────────────────────────────────────────┘
```

## Features

✅ Back button for navigation  
✅ Expandable/collapsible categories  
✅ Fixed card sizes for consistency  
✅ 2 items per row on mobile  
✅ 3 items per row on desktop  
✅ Dynamic total price calculation  
✅ Responsive layout using Wrap  
✅ Smooth expand/collapse animation ready  

## Testing Checklist

- [ ] Back button navigates to previous screen
- [ ] Categories expand/collapse on tap
- [ ] Expand/collapse icon changes correctly
- [ ] Cards maintain fixed size on mobile (2 per row)
- [ ] Cards maintain fixed size on desktop (160px width)
- [ ] Total price updates when services are selected
- [ ] Search still filters services correctly
- [ ] Consent badges display properly
- [ ] Selection state persists correctly
