USE Cyclistic
GO
	-- create stations table

DROP TABLE dbo.r_station_table
GO

SELECT start_station_name AS station_name
INTO Cyclistic.dbo.r_station_table
FROM
	(
	SELECT start_station_name
	FROM Cyclistic.dbo.d_trips_12months

UNION
	
	SELECT end_station_name
	FROM Cyclistic.dbo.d_trips_12months
	) AS table_1
GO
	
	--add new key for stations to correct for repeating station IDs

ALTER TABLE r_station_table
ADD station_key INT IDENTITY(1,1)
GO

	-- Update d_trips_12months with newly generated station_ids

UPDATE d_trips_12months
SET start_station_id = r_station_table.station_key
FROM d_trips_12months
LEFT JOIN r_station_table
ON d_trips_12months.start_station_name = r_station_table.station_name

UPDATE d_trips_12months
SET end_station_id = r_station_table.station_key
FROM d_trips_12months
LEFT JOIN r_station_table
ON d_trips_12months.end_station_name = r_station_table.station_name


	--create rides table

DROP TABLE dbo.d_ride_table
GO

SELECT *
INTO d_ride_table
FROM
	(
	SELECT ride_id, rideable_type, started_at, ended_at, start_station_id
	,end_station_id, member_casual, ride_in_seconds, ride_length, year_of_ride
	,month_of_ride, day_of_week
	FROM Cyclistic.dbo.d_trips_12months
	) AS table_2
GO

	-- create r_station_lat_lng
	-- contains all unique stations along with lat long values derived by taking the max of each value for each 
	-- unique station and truncating to 4 decimal places.

DROP TABLE dbo.r_station_lat_lon
GO

SELECT start_station_id AS station_id, ROUND(AVG(start_lat), 4, 1) AS lat, ROUND(AVG(start_lng), 4, 1) AS lon
INTO r_station_lat_lon
FROM
	(
	SELECT DISTINCT start_station_id,  start_lat, start_lng
	FROM dbo.d_trips_12months

	UNION

	SELECT DISTINCT end_station_id, end_lat, end_lng
	FROM dbo.d_trips_12months
	) AS table_3
GROUP BY start_station_id
GO
 