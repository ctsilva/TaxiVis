#!/bin/bash

# TaxiVis Data Processing Pipeline
# Processes raw NYC taxi CSV files into indexed .kdtrip format

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "TaxiVis Data Processing Pipeline"
echo "================================================"
echo ""

# Input files
TRIP_FILE="data/2012_trip_data_1.csv"
FARE_FILE="data/2012_trip_fare_1.csv"
MERGED_FILE="data/2012_merged.csv"
BINARY_FILE="data/2012_merged.trip"
KDTRIP_FILE="data/2012_merged.kdtrip"

# Check input files exist
if [ ! -f "$TRIP_FILE" ]; then
    echo -e "${RED}Error: $TRIP_FILE not found${NC}"
    exit 1
fi

if [ ! -f "$FARE_FILE" ]; then
    echo -e "${RED}Error: $FARE_FILE not found${NC}"
    exit 1
fi

echo "Input files:"
echo "  Trip data: $TRIP_FILE ($(du -h $TRIP_FILE | cut -f1))"
echo "  Fare data: $FARE_FILE ($(du -h $FARE_FILE | cut -f1))"
echo ""

# Step 1: Merge
echo -e "${GREEN}[Step 1/3] Merging trip and fare data (16 threads)...${NC}"
STEP1_START=$(date +%s)
julia -t 16 src/preprocess/merge.jl "$TRIP_FILE" "$FARE_FILE" "$MERGED_FILE"
STEP1_END=$(date +%s)
STEP1_TIME=$((STEP1_END - STEP1_START))
echo -e "${GREEN}✓ Merge completed in ${STEP1_TIME}s${NC}"
echo "  Output: $MERGED_FILE ($(du -h $MERGED_FILE | cut -f1))"
echo ""

# Step 2: Convert to binary
echo -e "${GREEN}[Step 2/3] Converting CSV to binary format (16 threads)...${NC}"
STEP2_START=$(date +%s)
julia -t 16 src/preprocess/csv2Binary_mt.jl "$MERGED_FILE" "$BINARY_FILE"
STEP2_END=$(date +%s)
STEP2_TIME=$((STEP2_END - STEP2_START))
echo -e "${GREEN}✓ Binary conversion completed in ${STEP2_TIME}s${NC}"
echo "  Output: $BINARY_FILE ($(du -h $BINARY_FILE | cut -f1))"
echo ""

# Step 3: Build KD-tree index
echo -e "${GREEN}[Step 3/3] Building KD-tree spatial index...${NC}"
STEP3_START=$(date +%s)
./build/src/preprocess/build_kdtrip "$BINARY_FILE" "$KDTRIP_FILE"
STEP3_END=$(date +%s)
STEP3_TIME=$((STEP3_END - STEP3_START))
echo -e "${GREEN}✓ KD-tree indexing completed in ${STEP3_TIME}s${NC}"
echo "  Output: $KDTRIP_FILE ($(du -h $KDTRIP_FILE | cut -f1))"
echo ""

# Summary
TOTAL_TIME=$((STEP1_TIME + STEP2_TIME + STEP3_TIME))
echo "================================================"
echo -e "${GREEN}Pipeline completed successfully!${NC}"
echo "================================================"
echo ""
echo "Timing Summary:"
echo "  Step 1 (Merge):          ${STEP1_TIME}s"
echo "  Step 2 (CSV to Binary):  ${STEP2_TIME}s"
echo "  Step 3 (Build KD-tree):  ${STEP3_TIME}s"
echo "  ----------------------------------------"
echo "  Total:                   ${TOTAL_TIME}s"
echo ""
echo "Output files:"
echo "  Merged CSV:  $MERGED_FILE"
echo "  Binary:      $BINARY_FILE"
echo "  Indexed:     $KDTRIP_FILE ← Load this in TaxiVis"
echo ""
echo "To use in TaxiVis, update querymanager.cpp line 10 to:"
echo "  std::string fname = string(DATA_DIR)+\"2012_merged.kdtrip\";"
echo ""
