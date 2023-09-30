USE Cyclistic

GO

DROP TABLE dbo.d_trips_12months
GO

	--create main data table from 12 months of Cyclistic data

CREATE TABLE Cyclistic.dbo.d_trips_12months(ride_id VARCHAR(50) PRIMARY KEY, rideable_type VARCHAR(50)
			,started_at DATETIME, ended_at DATETIME,start_station_name VARCHAR(MAX)
			,start_station_id VARCHAR(50), end_station_name VARCHAR(MAX), end_station_id VARCHAR(50)
			,start_lat FLOAT, start_lng FLOAT, end_lat FLOAT, end_lng FLOAT, member_casual VARCHAR(10))

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202204-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202205-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202205-divvy-tripdata_2.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202206-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202206-divvy-tripdata_2.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202207-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202207-divvy-tripdata_2.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202208-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202208-divvy-tripdata_2.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202209-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202209-divvy-tripdata_2.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202210-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202210-divvy-tripdata_2.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202211-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202212-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202301-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202302-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

BULK INSERT Cyclistic.dbo.d_trips_12months
FROM 'C:\Users\mahon\Documents\DivvyDataProject\Data\Divvy_12_months\202303-divvy-tripdata.csv'
WITH(FORMAT = 'CSV', FIRSTROW = 2);

 -- add and fill new columns day_of_week, ride_length, and ride_in_seconds

ALTER TABLE dbo.d_trips_12months
ADD year_of_ride INT,
month_of_ride INT,
day_of_week INT,
ride_length TIME,
ride_in_seconds INT

GO

UPDATE Cyclistic.dbo.d_trips_12months
SET day_of_week = DATEPART(WEEKDAY, started_at)
UPDATE Cyclistic.dbo.d_trips_12months
SET ride_length = CAST(ended_at AS datetime) - CAST(started_at AS datetime)
UPDATE Cyclistic.dbo.d_trips_12months
SET ride_in_seconds = DATEPART(HOUR, ride_length)*3600 + DATEPART(MINUTE, ride_length)*60 + DATEPART(SECOND, ride_length);

	-- clean the sales table --

	-- remove rows with no start or end station
DELETE
FROM dbo.d_trips_12months
WHERE start_station_name IS NULL OR end_station_name IS NULL

	--remove rows where ride is negative or 0 length
DELETE
FROM dbo.d_trips_12months
WHERE ride_in_seconds <= 0

-- remove rows where start time is greater than end time

DELETE
FROM dbo.d_trips_12months
WHERE started_at > ended_at

-- remove rides longer than 8 hours

DELETE
FROM dbo.d_trips_12months
WHERE ride_in_seconds > 3600*8

	-- Clear duplicate station names containing insignificant differences

UPDATE dbo.d_trips_12months
SET start_station_name = REPLACE(start_station_name, 'Public Rack - ', '')
UPDATE dbo.d_trips_12months
SET end_station_name = REPLACE(end_station_name, 'Public Rack - ', '')
UPDATE dbo.d_trips_12months
SET start_station_name = REPLACE(start_station_name, ' (TEMP)', '')
UPDATE dbo.d_trips_12months
SET end_station_name = REPLACE(end_station_name, ' (TEMP)', '')
UPDATE dbo.d_trips_12months
SET start_station_name = REPLACE(start_station_name, 'amp;', '')
UPDATE dbo.d_trips_12months
SET end_station_name = REPLACE(end_station_name, 'amp;', '')

--add columns for year, month, day, hours, and minutes.

UPDATE Cyclistic.dbo.d_trips_12months
SET month_of_ride = DATEPART(MONTH, started_at)
UPDATE Cyclistic.dbo.d_trips_12months
SET year_of_ride = DATEPART(YEAR, started_at)