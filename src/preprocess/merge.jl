#!/usr/bin/env julia

using CSV
using DataFrames

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
                     buffer_in_memory=true,
                     ntasks=Threads.nthreads())

    println("Loading fare data from: $fare_file")
    flush(stdout)
    fares = CSV.read(fare_file, DataFrame,
                     stripwhitespace=true,
                     buffer_in_memory=true,
                     ntasks=Threads.nthreads())

    println("Trips loaded: $(nrow(trips)) rows")
    println("Fares loaded: $(nrow(fares)) rows")

    # Rename columns to remove spaces for easier access
    rename!(trips, strip.(names(trips)))
    rename!(fares, strip.(names(fares)))

    println("Merging data...")
    # Merge on medallion, hack_license, vendor_id, and pickup_datetime
    merged = innerjoin(trips, fares,
                       on = [:medallion, :hack_license, :vendor_id, :pickup_datetime])

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
