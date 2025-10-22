# TaxiVis

A visual analytics application for exploring NYC taxi trip data using Qt5 and OpenGL.

## Current Status (Qt5 Migration)

**✅ Working:** Temporal series plots, histograms, scatter plots, data loading, selection graphs
**⚠️ Disabled:** Geographic map visualization (QtWebKit dependency - see [UPGRADE_PLAN.md](UPGRADE_PLAN.md))

## 1. Building from Source

### 1.1 Dependencies

**Required:**
- CMake 3.5 or higher
- Qt 5 (5.15+ recommended)
- Qt5 modules: Core, Gui, Widgets, OpenGL, Network, PrintSupport
- OpenGL/GLEW 2.2+
- Boost 1.42+ (components: iostreams, filesystem, timer)

**macOS Installation (Homebrew):**
```bash
brew install cmake qt@5 glew boost
```

**Linux Installation (Ubuntu/Debian):**
```bash
sudo apt-get install cmake qt5-default libqt5opengl5-dev libglew-dev libboost-all-dev
```

### 1.2 Compiling with CMake

```bash
cd src/TaxiVis
mkdir build
cd build

# macOS - set Qt5 path
export CMAKE_PREFIX_PATH="/opt/homebrew/opt/qt@5"

# Configure and build
cmake ..
make -j4
```

The executable `TaxiVis` will be created in the build directory.

### 1.3 Build Troubleshooting

**Qt5 not found:** Set `CMAKE_PREFIX_PATH` to your Qt5 installation:
```bash
export CMAKE_PREFIX_PATH="/path/to/qt5"
# macOS Homebrew: /opt/homebrew/opt/qt@5
# Linux: /usr/lib/x86_64-linux-gnu/qt5
```

**GLEW not found:** Ensure GLEW is installed via your package manager.

## 2. Running TaxiVis

### 2.1 Sample Data

A sample dataset of 10,000 trips from January 2013 is included in `data/sample_merged_1.kdtrip`.

The data directory is configured in [CMakeLists.txt](src/TaxiVis/CMakeLists.txt) (line 11):
```cmake
add_definitions(-DDATA_DIR=\"${CMAKE_CURRENT_SOURCE_DIR}/../../data/\")
```

### 2.2 Executing

From the build directory:
```bash
cd src/TaxiVis/build
./TaxiVis
```

### 2.3 Available Features

**Currently Working:**
- **Temporal Series Plots** - Visualize trip metrics over time (fare, distance, duration, etc.)
- **Histograms** - Distribution analysis of trip attributes
- **Scatter Plots** - Correlation analysis between variables
- **Selection Graphs** - Define spatial/temporal query regions
- **Color Scales** - Multiple color schemes for data visualization
- **Data Export** - Query and export trip subsets

**Temporarily Unavailable:**
- Geographic map view (requires QtWebEngine migration - see [UPGRADE_PLAN.md](UPGRADE_PLAN.md))
- Histogram/Temporal dialogs (depend on map widget)

## 3. Data Preprocessing

To index new taxi trip data, see the documentation in `doc/data_import.pdf`.

Preprocessing tools are in `src/preprocess/`:
```bash
cd src/preprocess
mkdir build
cd build
cmake ..
make
```

Available tools:
- `csv2Binary` - Convert CSV trip data to binary format
- `build_kdtrip` - Build spatial index for efficient querying
- `sampling` - Create subset samples of large datasets

## 4. Architecture

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

**Key Components:**
- **KdTrip** - Spatial indexing and query engine
- **SelectionGraph** - Graph-based spatial selection system
- **Rendering Layers** - OpenGL visualization (GridMap, HeatMap, TripAnimation, etc.)
- **QCustomPlot** - Plotting library for temporal/statistical views

## 5. Development

**Qt5 Migration Status:**
- ✅ All Qt4 → Qt5 API migrations complete
- ✅ OpenGL rendering updated (QGL → QOpenGL)
- ✅ Boost filesystem compatibility fixed
- ⚠️ Map components disabled pending QtWebEngine integration

See [UPGRADE_PLAN.md](UPGRADE_PLAN.md) for roadmap to restore map functionality.

**Build with:**
- Qt 5.15.17
- Boost 1.89.0
- GLEW 2.2.0
- CMake 4.1+

**Tested on:**
- macOS 26.0.1 (Apple Silicon)

## 6. References

- Original data source: http://www.andresmh.com/nyctaxitrips/
- Sample dataset: 10,000 trips from NYC Yellow Taxi, January 2013

## License

See original project documentation for license information.
