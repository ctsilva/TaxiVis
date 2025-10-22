# TaxiVis Upgrade Plan

## Current State Analysis

### System Environment
- **macOS**: 26.0.1 (latest)
- **CMake**: 4.1.2 ✓
- **Qt**: 6.9.3 (Homebrew) - **Incompatible** (need Qt 4 or upgrade code)
- **Boost**: Installed ✓
- **GLEW**: **Missing** ❌
- **Data**: Sample dataset present ✓

### Code Analysis
- **Language**: C++ with Qt4 framework
- **Total files**: ~104 source files
- **Qt dependencies**:
  - QtGui (Qt4 style headers)
  - QtWebKit (deprecated, removed in Qt 6)
  - QtOpenGL (replaced by QOpenGLWidget in Qt 5+)
  - Qt4 signals/slots syntax
- **OpenGL**: Uses legacy OpenGL 2.1 (GLSL 1.20)
- **Build system**: CMake 2.6+ (very old, but compatible)

### Critical Compatibility Issues

1. **Qt4 → Qt6 Migration**: Major breaking changes
   - Qt4 reached EOL in 2015
   - QtWebKit removed entirely from Qt 5.6+ (2016)
   - Module reorganization (QtGui split into QtGui/QtWidgets)
   - OpenGL API changes (QGLWidget → QOpenGLWidget)
   - Signal/slot syntax modernization

2. **QtWebKit Dependency**: 4 files use QtWebKit for web-based map tiles
   - QGraphicsWebView removed from Qt6
   - Requires either:
     - Building deprecated QtWebKit5 fork (complex)
     - Migrating to QtWebEngine (Qt's Chromium wrapper)
     - Alternative: Replace with tile image loading

3. **OpenGL Legacy Code**: Uses deprecated fixed-function pipeline
   - GLSL 1.20 is old but still supported on macOS
   - Should work with modern OpenGL compatibility profile

## Upgrade Strategy Options

### Option A: Stay on Qt4 (Quickest Path to Running)
**Complexity**: Low
**Time Estimate**: 1-2 hours
**Long-term Viability**: Poor (unmaintained)

**Steps**:
1. Install Qt4 via Homebrew (if available in older taps) or compile from source
2. Install GLEW: `brew install glew`
3. Update CMakeLists.txt to find Qt4 explicitly
4. Build with existing code unchanged
5. Test with sample data

**Pros**:
- Minimal code changes
- Fastest to get running
- No API migration needed

**Cons**:
- Qt4 unsupported since 2015
- May not compile on modern macOS toolchains
- Security vulnerabilities unfixed
- No future maintenance path

### Option B: Upgrade to Qt5 (Balanced Approach)
**Complexity**: Medium
**Time Estimate**: 4-8 hours
**Long-term Viability**: Good (Qt5 LTS until 2025)

**Steps**:
1. Install Qt5 and GLEW: `brew install qt@5 glew`
2. **Phase 1 - Module Updates** (~2 hours):
   - Update `#include <QtGui/...>` → split into QtGui/QtWidgets
   - Replace `QGLWidget` → `QOpenGLWidget`
   - Update CMakeLists.txt for Qt5 (find_package changes)

3. **Phase 2 - QtWebKit Replacement** (~3-4 hours):
   - **Option B1**: Build QtWebKit5 fork (complex, fragile)
   - **Option B2**: Migrate to QtWebEngine (Chromium-based)
   - **Option B3**: Replace web view with tile image loading (simpler)

4. **Phase 3 - API Modernization** (~1-2 hours):
   - Update signal/slot syntax (old → new)
   - Fix deprecated API calls
   - Update OpenGL context creation

5. **Phase 4 - Testing**:
   - Verify rendering layers work
   - Test data loading
   - Validate interactions

**Pros**:
- Stable, maintained Qt version
- Better macOS compatibility
- Cleaner migration path to Qt6 later
- QtWebEngine is official replacement

**Cons**:
- QtWebKit replacement is non-trivial
- Moderate code changes required
- Qt5 nearing EOL (2025)

### Option C: Full Upgrade to Qt6 (Future-Proof)
**Complexity**: High
**Time Estimate**: 12-20 hours
**Long-term Viability**: Excellent

**Steps**:
1. Use existing Qt6 installation + GLEW
2. All Phase 1-4 steps from Option B
3. Additional Qt6-specific migrations:
   - QStringRef removed (use QStringView)
   - QVector → QList consolidation
   - QRegExp → QRegularExpression
   - Build system updates for Qt6

**Pros**:
- Modern, actively developed
- Best performance
- Long-term support
- Latest features

**Cons**:
- Most time-intensive
- Higher risk of breaking changes
- May reveal more compatibility issues

## Recommended Approach: **Option B (Qt5)**

### Detailed Implementation Plan

#### Prerequisites (15 minutes)
```bash
# Install dependencies
brew install qt@5 glew

# Set Qt5 as default for this session
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/homebrew/opt/qt@5"
```

#### Phase 1: Basic Qt5 Compatibility (2 hours)

**1.1 Update CMakeLists.txt**
- Change `find_package(Qt4 REQUIRED)` → `find_package(Qt5 REQUIRED COMPONENTS ...)`
- Add Widgets component (split from Gui in Qt5)
- Update include/link variables
- Set minimum CMake version to 3.1 (for Qt5 support)

**1.2 Header Migration** (automated with sed/regex)
- `#include <QtGui/QApplication>` → `#include <QApplication>` + `find_package(Qt5 Widgets)`
- `#include <QtGui/Q*Widget>` → `#include <QWidget>` etc.
- Split QtGui headers into QtWidgets where needed
- Update .pro file if using qmake

**1.3 OpenGL Widget Update**
- `QGLWidget` → `QOpenGLWidget`
- `#include <QtOpenGL/QGLWidget>` → `#include <QOpenGLWidget>`
- Update OpenGL context initialization code

#### Phase 2: QtWebKit Replacement (3-4 hours)

**Recommended: Use QtWebEngine**
- Replace `#include <QtWebKit/...>` → `#include <QtWebEngine/...>`
- `QGraphicsWebView` → Custom `QWebEngineView` in QGraphicsProxyWidget
- Update map JavaScript interaction API
- May need to adjust web page loading mechanism

**Alternative: Lightweight Tile Loader**
- Remove web view dependency entirely
- Implement direct OpenStreetMap tile loading via QNetworkAccessManager
- Render tiles as OpenGL textures
- Simpler but loses interactive web map features

#### Phase 3: Code Modernization (1-2 hours)
- Update signal/slot connections to new syntax (optional but recommended)
- Fix deprecated API warnings
- Update CMake policies for modern CMake
- Adjust OpenGL initialization for Qt5

#### Phase 4: Build & Test (1-2 hours)
- Clean build directory
- Run cmake with Qt5
- Fix compilation errors iteratively
- Test with sample_merged_1.kdtrip data
- Verify all visualization layers render correctly

#### Phase 5: Documentation (30 minutes)
- Update CLAUDE.md with Qt5 build instructions
- Document any API changes
- Note remaining issues/limitations

### Risk Mitigation

1. **Create git branch**: `git checkout -b qt5-upgrade`
2. **Backup current state**: Tag current state as `qt4-original`
3. **Incremental commits**: Commit after each phase
4. **Test data safety**: Don't modify data files
5. **Fallback plan**: Keep Option A available if Option B fails

### Success Criteria

- [ ] Application compiles without errors
- [ ] Application launches and shows main window
- [ ] Sample data loads successfully
- [ ] Map view renders (with tiles or without)
- [ ] OpenGL rendering layers display correctly
- [ ] Time series plots render
- [ ] Histograms display
- [ ] User interactions work (selection, zoom, pan)

### Post-Upgrade Tasks

1. Test all visualization features
2. Verify data query performance
3. Check for memory leaks (Qt5 has better tooling)
4. Update documentation
5. Consider containerization (Docker) for reproducibility

## Alternative: Minimal Running Version

If full upgrade is too complex, consider:
1. Install Qt4 from source (MacPorts still maintains it)
2. Or: Use Docker container with Ubuntu 18.04 + Qt4
3. Or: Virtual machine with older macOS/Linux

This provides quickest path to "running" state but with no future development path.

## Estimated Total Time

- **Option A**: 1-2 hours (but likely to fail on modern macOS)
- **Option B**: 8-12 hours (realistic estimate with testing)
- **Option C**: 15-20 hours (most thorough)

## Recommendation

**Start with Option B (Qt5)**, proceeding in phases:
1. Begin with Phase 1 (basic compatibility) - if successful, continue
2. For Phase 2, try QtWebEngine first; if too complex, fall back to tile loader
3. If Qt5 proves too difficult, fall back to Docker/VM approach with Qt4

Would you like me to proceed with Option B (Qt5 upgrade)?
