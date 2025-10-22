# TaxiVis

A visual analytics application for exploring NYC taxi trip data using Qt5 and OpenGL.

## Current Status (Qt5 Migration)

**✅ Working:** Temporal series plots, histograms, scatter plots, data loading, selection graphs
**⚠️ Disabled:** Geographic map visualization (QtWebKit dependency - see [UPGRADE_PLAN.md](UPGRADE_PLAN.md))

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

TaxiVis requires taxi trip data in a specialized binary format (.kdtrip). The preprocessing pipeline converts raw CSV data into this indexed format for efficient querying.

### 3.1 Overview

The preprocessing workflow:
1. **CSV → Binary** - Convert CSV trip records to binary Trip format
2. **Binary → KdTrip** - Build KD-tree spatial index for fast queries
3. **(Optional)** - Sample or merge datasets

All preprocessing tools are built automatically in `build/src/preprocess/`.

### 3.2 Preprocessing Tools

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

### 3.3 Complete Preprocessing Pipeline

**Step 1: Convert CSV to binary Trip format**
```bash
./build/src/preprocess/csv2Binary data/raw_trips.csv data/trips.trip
```

**Step 2: Build KD-tree index**
```bash
./build/src/preprocess/build_kdtrip data/trips.trip data/trips.kdtrip
```

**Step 3: Load in TaxiVis**
```bash
./build/src/TaxiVis/TaxiVis
# File → Open → data/trips.kdtrip
```

### 3.4 Data Format Reference

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
