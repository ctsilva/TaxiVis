# Map Restoration Plan

## Problem Statement

TaxiVis requires a map widget for its core functionality, but the original implementation used QtWebKit (QGraphicsWebView), which was deprecated and removed from Qt 5.6+. The Qt5 migration disabled map functionality using `NO_WEBKIT` preprocessor guards.

## Current Architecture

The map system has three layers:

1. **QMapWidget** (QGraphicsView) - Container widget
   - Sets up QGraphicsScene
   - Manages viewport with OpenGL rendering
   - Handles resize events

2. **QMapView** (QGraphicsWebView) - Web view showing Google Maps
   - Embeds in QGraphicsScene
   - Loads Google Maps via HTML/JavaScript
   - Handles pan/zoom interactions
   - Provides coordinate transformations (lat/lon ↔ screen coordinates)

3. **RenderingLayers** - OpenGL overlays on top of map
   - Trip points (blue = pickup, red = dropoff)
   - Heat maps
   - Neighborhood aggregations
   - Selection regions (polygons, arrows)

**Key Design**: QGraphicsWebView allows embedding a web browser in a QGraphicsScene, which can then be overlaid with OpenGL-rendered content using QPainter in the `paint()` method.

## Migration Options Evaluated

### Option A: QtWebEngine (Qt5 Official Replacement)
**Status**: ❌ **Rejected**

**Why rejected**:
- QtWebEngine has no QGraphicsWebView equivalent
- Only provides QWebEngineView (standard QWidget)
- Cannot be embedded in QGraphicsScene
- Rendering happens in separate Chromium process
- Would require complete architecture redesign
- No direct QPainter integration

**Effort**: 🔴 High (3-4 weeks) - Complete rewrite of widget hierarchy

### Option B: Custom Tile-Based Map
**Status**: ⏸️ **Deferred** (fallback option)

**Pros**:
- No web engine dependency
- Native Qt/OpenGL integration
- Lighter weight
- Better performance
- Future-proof

**Cons**:
- Need to implement tile loading from OpenStreetMap
- Need to implement pan/zoom logic
- More upfront development

**Effort**: 🟡 Medium (1-2 weeks)

**Implementation outline**:
1. Replace QGraphicsWebView with custom QGraphicsWidget
2. Implement tile loading (HTTP requests to tile servers)
3. Implement tile caching and rendering
4. Implement pan/zoom transforms
5. Keep all existing RenderingLayers unchanged

### Option C: QtWebKit from 3rd Party Source
**Status**: ✅ **Selected** (trying first)

**Why selected**:
- Minimal code changes required
- QGraphicsWebView API remains available
- Maintains current architecture intact
- Quickest path to working map
- Can fall back to Option B if issues arise

**Cons**:
- Not officially supported by Qt
- Security concerns (outdated browser engine for 2011 data)
- Dependency on 3rd party package

**Effort**: 🟢 Low (1-2 days)

## Implementation Plan: Option C

### Step 1: Install QtWebKit
```bash
brew install qt-webkit@5
```

### Step 2: Update CMakeLists.txt
- Remove `NO_WEBKIT` definition
- Find and link Qt5WebKit and Qt5WebKitWidgets packages
- Re-enable map-related source files

### Step 3: Update Source Files
- Remove `#ifndef NO_WEBKIT` guards from:
  - mainwindow.cpp
  - coordinator.cpp
  - geographicalviewwidget.h/cpp
  - QMapWidget.cpp

### Step 4: Fix Build Issues
- Resolve any API incompatibilities
- Update deprecated Qt5 APIs if needed

### Step 5: Test
- Verify map loads with Google Maps tiles
- Test pan/zoom functionality
- Test spatial query features (polygon selection, etc.)
- Verify rendering layers work correctly

### Fallback Criteria

Switch to **Option B** (custom tiles) if:
- QtWebKit package is unavailable or incompatible
- Build errors are too complex to resolve quickly (>1 day)
- Runtime crashes or instability
- Google Maps no longer works with old QtWebKit

## Current Status

- **Date**: 2025-10-22
- **Branch**: qt5-upgrade
- **Checkpoint commit**: (to be created)
- **Attempting**: Option C (QtWebKit from 3rd party)

## Files Modified for NO_WEBKIT Guards

Core files that need guards removed:

1. `src/TaxiVis/mainwindow.cpp` - Map initialization on startup
2. `src/TaxiVis/coordinator.cpp` - ViewWidget management
3. `src/TaxiVis/geographicalviewwidget.h` - Inheritance from QMapWidget
4. `src/TaxiVis/QMapWidget.cpp` - WebKit settings
5. `src/TaxiVis/CMakeLists.txt` - Build configuration

Disabled files (currently commented out in CMakeLists.txt):
- QMapView.cpp
- QMapWidget.cpp
- viewwidget.cpp
- geographicalviewwidget.cpp

## References

- [QtWebKit 5.212 Documentation](https://github.com/qt/qtwebkit)
- [OpenStreetMap Tile Servers](https://wiki.openstreetmap.org/wiki/Tile_servers)
- [Leaflet.js](https://leafletjs.com/) - For Option B reference
- UPGRADE_PLAN.md - Original Qt5 migration plan
