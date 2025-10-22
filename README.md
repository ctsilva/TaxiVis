# TaxiVis

A visual analytics application for exploring NYC taxi trip data using Qt5 and OpenGL.

## Current Status (Qt5 Migration)

**✅ Complete:** Qt5 migration finished! All features working including OpenStreetMap tile-based geographic visualization.

## 1. Building from Source

### 1.1 Dependencies

**Required:**
- CMake 3.10 or higher
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

**Build everything (recommended):**
```bash
mkdir build
cd build

# macOS - set Qt5 path
export CMAKE_PREFIX_PATH="/opt/homebrew/opt/qt@5"

# Configure and build both TaxiVis and preprocessing tools
cmake ..
make -j4
```

This builds:
- `src/TaxiVis/TaxiVis` - Main visualization application
- `src/preprocess/csv2Binary` - CSV converter
- `src/preprocess/build_kdtrip` - KD-tree indexer
- `src/preprocess/multiCsv2Binary` - Batch CSV converter
- `src/preprocess/newFormatCsv2Binary` - Alternative CSV converter
- `src/preprocess/sampling` - Data sampling tool
- `src/preprocess/testQuery` - Query testing utility
- `src/preprocess/unif96_to_bin` - Legacy format converter

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
./src/TaxiVis/TaxiVis
```

### 2.3 Available Features

- **Geographic Map View** - OpenStreetMap tile-based visualization with pan/zoom
  - Three-tier caching: memory → disk → network
  - Persistent tile cache at `~/Library/Caches/TaxiVis/tiles` (macOS) or `~/.cache/TaxiVis/tiles` (Linux)
  - Keyboard controls: Arrow keys to pan, +/- to zoom
- **Temporal Series Plots** - Visualize trip metrics over time (fare, distance, duration, etc.)
- **Histograms** - Distribution analysis of trip attributes
- **Scatter Plots** - Correlation analysis between variables
- **Selection Graphs** - Define spatial/temporal query regions
- **Color Scales** - Multiple color schemes for data visualization
- **Data Export** - Query and export trip subsets

### 2.4 Known Limitations

- **Animated Trip Paths (TripAnimation)** - Disabled on macOS due to geometry shader compatibility issues
  - Alternative: Use TripLocation layer to visualize pickup/dropoff points
- **File → Open Dialog** - Not yet implemented; change dataset in [querymanager.cpp](src/TaxiVis/querymanager.cpp#L10) and rebuild

## 3. Data Preprocessing

TaxiVis requires taxi trip data in a specialized binary format (.kdtrip). The preprocessing pipeline converts raw CSV data into this indexed format for efficient querying.

### 3.1 Overview

The preprocessing workflow:
1. **Merge** - Combine trip and fare CSV files
2. **CSV → Binary** - Convert merged CSV to binary Trip format
3. **Binary → KdTrip** - Build KD-tree spatial index for fast queries

**Recommended:** Use the Julia-based pipeline for 10-15x faster processing (requires Julia 1.6+).
All preprocessing tools are in `src/preprocess/` (Julia) and `build/src/preprocess/` (C++).

### 3.2 Quick Start (Julia Pipeline - Recommended)

**Requirements:**
- Julia 1.6+ installed
- Raw NYC taxi CSV files (trip_data and trip_fare)

**Automated Pipeline:**
```bash
# Process your data in one command
./process_taxi_data.sh
```

The script automatically:
1. Merges trip and fare data (multithreaded)
2. Converts to binary format (multithreaded)
3. Builds KD-tree spatial index
4. Displays timing statistics

**Performance:** Processes ~15 million trips (4GB CSV) in ~2-5 minutes on 16 cores.

**Manual Julia Commands:**
```bash
# Step 1: Merge trip and fare CSVs
julia -t 16 src/preprocess/merge.jl data/trip_data.csv data/trip_fare.csv data/merged.csv

# Step 2: Convert to binary
julia -t 16 src/preprocess/csv2Binary_mt.jl data/merged.csv data/merged.trip

# Step 3: Build KD-tree index
./build/src/preprocess/build_kdtrip data/merged.trip data/merged.kdtrip
```

### 3.3 C++ Preprocessing Tools (Legacy)

#### csv2Binary
Converts a single CSV file to binary Trip format.

**CSV Format Expected:**
```
pickup_time,dropoff_time,pickup_long,pickup_lat,dropoff_long,dropoff_lat,id_taxi,distance,fare_amount,surcharge,mta_tax,tip_amount,tolls_amount,payment_type,passengers,field1,field2,field3,field4
```

**Usage:**
```bash
./build/src/preprocess/csv2Binary input.csv output.trip
```

**Example:**
```bash
./build/src/preprocess/csv2Binary data/trips_2013-01.csv data/trips_2013-01.trip
```

#### multiCsv2Binary
Processes multiple CSV files listed in an index file. Useful for batch processing large datasets split across files.

**Usage:**
```bash
./build/src/preprocess/multiCsv2Binary file_list.txt output.trip
```

**file_list.txt format:**
```
/path/to/trips_2013-01-01.csv
/path/to/trips_2013-01-02.csv
/path/to/trips_2013-01-03.csv
```

#### newFormatCsv2Binary
Converts NYC taxi data in the newer format (post-2015) where column order differs.

**Usage:**
```bash
./build/src/preprocess/newFormatCsv2Binary input.csv output.trip
```

#### build_kdtrip
Builds a KD-tree spatial index from binary Trip data. This is the final step - produces the `.kdtrip` file that TaxiVis loads.

**Usage:**
```bash
./build/src/preprocess/build_kdtrip input.trip output.kdtrip
```

**Example:**
```bash
./build/src/preprocess/build_kdtrip data/trips_2013-01.trip data/trips_2013-01.kdtrip
```

**Output:** Creates a KD-tree index optimized for 7-dimensional queries:
- pickup_time
- dropoff_time
- pickup_longitude
- pickup_latitude
- dropoff_longitude
- dropoff_latitude
- taxi_id

#### sampling
Creates a spatially-filtered sample from a .kdtrip file. Filters trips by census tract geometry and time range.

**Usage:**
```bash
./build/src/preprocess/sampling input.kdtrip skip_factor output.csv
```

**Example (10% sample):**
```bash
./build/src/preprocess/sampling data/trips_2013.kdtrip 10 data/sample_10pct.csv
```

**Note:** Requires `data/census_tracts_geom.txt` geometry file.

#### testQuery
Tests KdTrip query functionality on a .kdtrip file. Useful for verifying index correctness.

**Usage:**
```bash
./build/src/preprocess/testQuery input.kdtrip
```

#### unif96_to_bin
Converts legacy 96-byte uniform binary format to the current Trip format. Only needed for old archived datasets.

**Usage:**
```bash
./build/src/preprocess/unif96_to_bin input.bin output.trip
```

#### merge.py
Python script to merge separate trip and fare CSV files into the unified format.

**Usage:**
```bash
python src/preprocess/merge.py trips.csv fares.csv merged.csv
```

### 3.4 Loading Data in TaxiVis

**Option 1: Update default dataset** (edit [querymanager.cpp:10](src/TaxiVis/querymanager.cpp#L10)):
```cpp
std::string fname = string(DATA_DIR)+"your_data.kdtrip";
```
Then rebuild TaxiVis.

**Option 2: File → Open** (not yet implemented in current version)

The application will display:
- Number of trips loaded
- Time range of the dataset
- Data statistics on startup

### 3.5 Data Format Reference

**Binary Trip Structure (48 bytes):**
- `uint32_t pickup_time` - Unix timestamp (seconds since epoch)
- `uint32_t dropoff_time` - Unix timestamp
- `float pickup_long` - Pickup longitude
- `float pickup_lat` - Pickup latitude
- `float dropoff_long` - Dropoff longitude
- `float dropoff_lat` - Dropoff latitude
- `uint16_t id_taxi` - Taxi/medallion ID
- `uint16_t distance` - Distance in 0.01 miles (divide by 100)
- `uint16_t fare_amount` - Fare in cents (divide by 100)
- `uint16_t surcharge` - Surcharge in cents
- `uint16_t mta_tax` - MTA tax in cents
- `uint16_t tip_amount` - Tip in cents
- `uint16_t tolls_amount` - Tolls in cents
- `uint8_t payment_type` - Payment method code
- `uint8_t passengers` - Number of passengers
- `uint16_t field1, field2, field3, field4` - Custom/region fields

## 4. Architecture

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

**Key Components:**
- **KdTrip** - Spatial indexing and query engine
- **QMapTileWidget** - Custom OpenStreetMap tile-based map widget with caching
- **SelectionGraph** - Graph-based spatial selection system
- **Rendering Layers** - OpenGL visualization (GridMap, HeatMap, TripAnimation, etc.)
- **QCustomPlot** - Plotting library for temporal/statistical views

## 5. Development

**Qt5 Migration Status:**
- ✅ All Qt4 → Qt5 API migrations complete
- ✅ OpenGL rendering updated (QGL → QOpenGL)
- ✅ Boost filesystem compatibility fixed
- ✅ Map visualization restored with OpenStreetMap tile-based widget
- ✅ QtWebKit dependency removed (replaced with QNetworkAccessManager)

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
