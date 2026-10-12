#!/usr/bin/env julia

using CSV
using DataFrames

# Read the time columns as text, so that the merged CSV keeps their original
# format with any CSV.jl version (>= 1.0 parses them into its own type).
# Keys are the stripped header names (stripwhitespace=true strips them).
const TIME_COLUMNS = ("pickup_datetime", "dropoff_datetime")
function time_columns_as_string(path)
    header = split(readline(path), ',')
    return Dict{Symbol, Type}(Symbol(strip(h)) => String for h in header if strip(h) in TIME_COLUMNS)
end

const KEYS = [:medallion, :hack_license, :vendor_id, :pickup_datetime]

"""
Trips and fares side by side. The 2013 TLC trip and fare files are aligned line
by line: when every row's key matches, pair rows by position. Joining on the key
would multiply rows whose key repeats (April 2013: 652 keys shared by distinct
trips, +1,304 rows; August: +4,028). Otherwise, join on the key and report
repeated keys.
"""
function merge_trips_fares(trips, fares)
    if nrow(trips) == nrow(fares) && all(all(trips[!, k] .== fares[!, k]) for k in KEYS)
        println("Trip and fare files are aligned: merging by position")
        return hcat(trips, select(fares, Not(KEYS)))
    end
    repeated = nrow(trips) - nrow(unique(trips[!, KEYS]))
    repeated > 0 && println("Warning: $repeated trip rows repeat a key; the join multiplies them")
    println("Trip and fare files are not aligned: joining on $(KEYS)")
    return innerjoin(trips, fares, on = KEYS)
end

function main()
    if length(ARGS) != 3
        println("Usage: julia -t auto merge.jl <trips data> <fare data> <output file>")
        println("Note: Use -t auto or -t 16 to enable multithreading")
        exit(1)
    end

    trip_file = ARGS[1]
    fare_file = ARGS[2]
    output_file = ARGS[3]

    println("Using $(Threads.nthreads()) threads")
    println()

    println("Loading trip data from: $trip_file")
    flush(stdout)
    trips = CSV.read(trip_file, DataFrame,
                     stripwhitespace=true,
                     types=time_columns_as_string(trip_file),
                     buffer_in_memory=true,
                     ntasks=Threads.nthreads())

    println("Loading fare data from: $fare_file")
    flush(stdout)
    fares = CSV.read(fare_file, DataFrame,
                     stripwhitespace=true,
                     types=time_columns_as_string(fare_file),
                     buffer_in_memory=true,
                     ntasks=Threads.nthreads())

    println("Trips loaded: $(nrow(trips)) rows")
    println("Fares loaded: $(nrow(fares)) rows")

    # Rename columns to remove spaces for easier access
    rename!(trips, strip.(names(trips)))
    rename!(fares, strip.(names(fares)))

    println("Merging data...")
    merged = merge_trips_fares(trips, fares)

    println("Merged: $(nrow(merged)) rows")

    # Create output dataframe with required columns
    println("Formatting output...")
    output = DataFrame(
        pickup_time = merged.pickup_datetime,
        dropoff_time = merged.dropoff_datetime,
        pickup_long = merged.pickup_longitude,
        pickup_lat = merged.pickup_latitude,
        dropoff_long = merged.dropoff_longitude,
        dropoff_lat = merged.dropoff_latitude,
        id_taxi = merged.medallion,
        distance = merged.trip_distance,
        fare_amount = merged.fare_amount,
        surcharge = merged.surcharge,
        mta_tax = merged.mta_tax,
        tip_amount = merged.tip_amount,
        tolls_amount = merged.tolls_amount,
        payment_type = merged.payment_type,
        passengers = merged.passenger_count,
        field1 = zeros(Int, nrow(merged)),
        field2 = zeros(Int, nrow(merged)),
        field3 = zeros(Int, nrow(merged)),
        field4 = zeros(Int, nrow(merged))
    )

    println("Writing output to: $output_file")
    CSV.write(output_file, output)

    println("Done! Processed $(nrow(output)) trips")
end

main()
