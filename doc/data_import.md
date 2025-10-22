# TaxiVis Data Import Guide

This document explains the process of importing data into the TaxiVis system.

## Data Schema

The current version uses a fixed schema represented by the following struct (found in [KdTrip.hpp](../src/TaxiVis/KdTrip.hpp)):

```c
struct Trip {
    uint32_t  pickup_time;
    uint32_t  dropoff_time;
    float     pickup_long;
    float     pickup_lat;
    float     dropoff_long;
    float     dropoff_lat;
    uint32_t  field1;         // extra field to import data
    uint32_t  field2;         // extra field to import data
    uint32_t  field3;         // extra field to import data
    uint32_t  field4;         // extra field to import data
    uint16_t  id_taxi;
    uint16_t  distance;
    uint16_t  fare_amount;
    uint16_t  surcharge;
    uint16_t  mta_tax;
    uint16_t  tip_amount;
    uint16_t  tolls_amount;
    uint8_t   payment_type;
    uint8_t   passengers;
};
```

This schema includes the attributes present in the data released by the New York City Taxi & Limousine Commission (TLC). We have also included additional attributes (`field1`, `field2`, `field3`, and `field4`) to allow for additional data that may be required by different applications.

## Data Import Process Overview

![Data Import Process](figs/process.png)

*Summary of the data import process*

## Importing the Data and Building the Index

The source code for building the index is in the [src/preprocess](../src/preprocess) folder. The data import process is illustrated in the figure above.

### Step 1: Merge Trip and Fare Files (Legacy Format)

The inputs are two separate sets of CSV files (provided by the TLC): trip files and fare files.

Two sample data files (`sample_trip_data_1.csv` and `sample_trip_fare_1.csv`) are included in the `data/rawData` folder.

The `merge.py` script merges these files into a single CSV file. This script also adds the placeholder columns `field1`, `field2`, `field3`, and `field4` (default values are all zeros, but additional data might be derived and imported here).

**Usage:**
```bash
python merge.py sample_trip_data_1.csv sample_trip_fare_1.csv merged_test_data.csv
```

### Step 2: Convert CSV to Binary Format

The merged file is then serialized as a binary file. This is done so that the index construction can scale to large volumes of data.

There are two programs that can accomplish this:

#### csv2Binary

Processes **one** CSV file and outputs a corresponding binary file.

**Usage:**
```bash
./csv2Binary merged_test_data.csv bin_test_data.bin
```

#### multiCsv2Binary

Takes as input a file containing a **list** of CSV files to be processed and outputs a single binary file containing all the trips in the input files.

**Example input file** (`fileLocations.txt`):
```
../../data/rawData/data_1.csv
../../data/rawData/data_2.csv
```

**Usage:**
```bash
./multiCsv2Binary fileLocations.txt bin_test_data.bin
```

### Step 3: Build the KD-Tree Index

The `build_kdtrip` script takes as input the binary file containing the trip records and outputs the kdtrip index that is loaded by TaxiVis.

**Usage:**
```bash
./build_kdtrip bin_test_data.bin test_data.kdtrip
```

## Parsing Files from TLC Website (New Format)

TLC now releases data at [http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml](http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml).

To parse this data into TaxiVis format, we can use a process similar to the one described above. In this new format, fare and trip files are already integrated, so there is no need to use the merge script.

Instead, use the `newFormatCsv2Binary` parser:

**Usage:**
```bash
./newFormatCsv2Binary yellow_tripdata_2015-01.csv bin_test_data.bin
```

Once this is done, proceed with the `build_kdtrip` step to build the index to be used in TaxiVis.

## Loading File in TaxiVis

The kdtrip file is loaded by TaxiVis using the constructor of the `QueryManager` class ([querymanager.cpp](../src/TaxiVis/querymanager.cpp)):

```cpp
std::string fname = "/path/to/file/test_data.kdtrip";
```

Once this change is made and TaxiVis is run, the file will be loaded.

## Configuring Placeholder Fields in TaxiVis

To configure how the placeholder fields are displayed in TaxiVis, we include a configuration file called `extra_fields.txt` (located in the data directory).

This is a CSV file with the following format:

```
field1,Screen Name1,Axis Label1,DisplayValue
field2,Screen Name2,Axis Label2,DisplayValue
field3,Screen Name3,Axis Label3,DisplayValue
field4,Screen Name4,Axis Label4,DisplayValue
```

**Field descriptions:**
- **Column 1:** Internal name used for the attribute in the code
- **Column 2:** Label shown in the interface
- **Column 3:** Text used to label the axis in plots that use this field
- **Column 4:** Display flag (1 = active, 0 = inactive)

![TaxiVis Interface](figs/taxivis.png)

*TaxiVis showing the new data file*

## Complete Workflow Examples

### Legacy Format (Separate Trip/Fare Files)

```bash
# 1. Merge trip and fare files
python src/preprocess/merge.py data/rawData/sample_trip_data_1.csv \
                                data/rawData/sample_trip_fare_1.csv \
                                data/merged_test_data.csv

# 2. Convert to binary
./build/src/preprocess/csv2Binary data/merged_test_data.csv data/bin_test_data.bin

# 3. Build KD-tree index
./build/src/preprocess/build_kdtrip data/bin_test_data.bin data/test_data.kdtrip

# 4. Load in TaxiVis (update querymanager.cpp with path to data/test_data.kdtrip)
```

### New Format (Integrated Trip Files from TLC Website)

```bash
# 1. Download from TLC website
wget http://www.nyc.gov/html/tlc/downloads/yellow_tripdata_2015-01.csv

# 2. Convert to binary
./build/src/preprocess/newFormatCsv2Binary yellow_tripdata_2015-01.csv data/bin_2015-01.bin

# 3. Build KD-tree index
./build/src/preprocess/build_kdtrip data/bin_2015-01.bin data/trips_2015-01.kdtrip

# 4. Load in TaxiVis (update querymanager.cpp with path to data/trips_2015-01.kdtrip)
```

### Batch Processing Multiple Files

```bash
# 1. Create file list
cat > fileLocations.txt << EOF
data/rawData/merged_2013-01.csv
data/rawData/merged_2013-02.csv
data/rawData/merged_2013-03.csv
EOF

# 2. Process all files to single binary
./build/src/preprocess/multiCsv2Binary fileLocations.txt data/all_2013_q1.bin

# 3. Build KD-tree index
./build/src/preprocess/build_kdtrip data/all_2013_q1.bin data/trips_2013_q1.kdtrip

# 4. Load in TaxiVis
```
