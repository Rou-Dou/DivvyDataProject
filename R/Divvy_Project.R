#################### Import Libraries ###################

library(ggmap)
library(ggplot2)
library(dplyr)
library(tidyverse)
library(lubridate)
library(maps)
library(ggthemes)
library(ggrepel)
library(rstudioapi)
library(data.table)
library(broom)
library(gridExtra)

########################### Functions #####################################

# create function to find mode

getmode <- function(x){
  u <- unique(x)
  t <- tabulate(match(x, u))
  return(u[t == max(t)])
}

# Donut graphs require same inputs, created function to clean
# up code

createDonut <- function (x, filter_text){
  
  x %>%
    filter(member_type == filter_text) -> x_prime
  
  x_prime$fraction <- x_prime$ride_count/
    sum(x_prime$ride_count)
  x_prime$ymax <- cumsum(x_prime$fraction)
  x_prime$ymin <- c(0, head(x_prime$ymax, n=-1))
  x_prime$labelPosition <- (x_prime$ymax + x_prime$ymin)/2
  x_prime$season <- c('Winter', 'Spring', 'Summer', 'Fall')
  
  return(x_prime)
  
}

# Trip totals are calculated the same for both tables
# created function to reduce redundancy

trip_totals <- function (table_in, filter_name){
  
  ## Create Top_ten_trips table including both counts and lat/lon
  ## coordinates
  
  table_in %>%
    filter(member_type == filter_name) -> a
  
  merge(x = a, y = r_station_pairs,
        by = 'pair_id') %>%
    arrange(desc(trip_count)) %>%
    subset(select = c('start_station_id', 'end_station_id', 'trip_count')) %>%
    head(10) -> b
  
  
  ##Add coordinate information to top_ten_stations using r_station_lat_lng
  merge(x = r_station_lat_lng, y = b,
        by.x = 'station_id', by.y = 'start_station_id') %>%
    merge(y = r_station_lat_lng, by.x = 'end_station_id', 
          by.y = 'station_id') -> b
  
  b <- setcolorder(b, c(2,3,4,1,6,7,5))
  
  return(b)
}

            ############ Data Import ############


list.files(pattern = 'd_ride') %>%
  map_df(~fread(header = FALSE, .)) -> d_ride_table

r_station_lat_lng <- read.csv(
  "cyclistic_r_station_lat_lon.csv", 
                              header = FALSE)
r_station_table <- read.csv(
  "cyclistic_r_station_table.csv", 
                            header = FALSE)

setDT(d_ride_table)

# rename columns

names(r_station_lat_lng) <- c('station_id', 'lat', 'lon')
names(d_ride_table) <- c('ride_id', 'rideable_type', 'started_at', 'ended_at',
                         'start_station_id', 'end_station_id',
                         'member_casual', 'ride_in_seconds',
                         'ride_length', 'year_of_ride', 'month_of_ride',
                         'day_of_week')
names(r_station_table) <- c('station_name', 'station_key')

## reclassify datetimes as POSIX
d_ride_table$started_at <- as_datetime(d_ride_table$started_at)
d_ride_table$ended_at <- as_datetime(d_ride_table$ended_at)


            ############ Table Creation #############


## create ride table with only casual member entries    
d_ride_table %>% filter(member_casual == 'casual') -> d_ride_table_c
head(d_ride_table_c,10)

setDT(d_ride_table_c)


## create ride table with only member entries
d_ride_table %>% filter(member_casual == 'member') -> d_ride_table_m
head(d_ride_table_m,10)

setDT(d_ride_table_m)


#create a table containing all start/end station pairs in the data set
d_ride_table %>%
  subset(select = c('start_station_id', 'end_station_id')) %>%
  unique() -> r_station_pairs
head(r_station_pairs,10)


#create unique id for each pair of start/end stations
r_station_pairs$pair_id <- c(1:nrow(r_station_pairs)) 
r_station_pairs <- setcolorder(r_station_pairs, c(3,1,2)) #reorder columns
head(r_station_pairs,10)


## Create final station pair table with station_names
merge(x = r_station_pairs, y = r_station_table,
      by.x = 'start_station_id', by.y = 'station_key') %>%
  merge(y = r_station_table, by.x = 'end_station_id', by.y = 'station_key') -> 
  r_station_pairs
r_station_pairs <- setcolorder(r_station_pairs,c(3,4,2,5,1)) #reorder columns
names(r_station_pairs)[2] <- 'start_station_name' #rename column
names(r_station_pairs)[4] <- 'end_station_name' #rename column

setDT(r_station_pairs)
head(r_station_pairs,10)


#create table containing all rides and include start/end station pair ids
d_ride_table %>%
  subset(select = c('ride_id', 'start_station_id', 'end_station_id', 
                    'member_casual')) -> d_ride_table_prime

merge(x=d_ride_table_prime, y=r_station_pairs,
      by.x = c('start_station_id', 'end_station_id'),
      by.y = c('start_station_id', 'end_station_id')) -> d_station_pair_merge



d_station_pair_merge <- setcolorder(d_station_pair_merge,
                                    c(3,4,1,2)) #reorder columns
rm(d_ride_table_prime)
head(d_station_pair_merge,10)


#create table with total trips taken from all station pairs
  d_station_pair_merge[, .(.N), by = .(pair_id, 
                       member_casual)] -> d_station_trip_totals
  
names(d_station_trip_totals) <- c('pair_id', 'member_type', 'trip_count')
setcolorder(d_station_trip_totals, c(1,3,2)) #reorder columns
head(d_station_trip_totals,10) 


## create new table containing only weekday information
d_ride_table %>%
  filter(day_of_week < 6) %>%
  subset(select = c(ride_id, start_station_id, end_station_id,
                    started_at, ended_at, day_of_week,
                    ride_in_seconds))  %>%
  arrange(started_at) -> d_ride_table_weekday

head(d_ride_table_weekday, 10)

setDT(d_ride_table_weekday)

#Create table that counts bike type by member status.
#Removed docked_bike option as it is not used by members
#So there is no comparison to be made
rideable_type_count <- d_ride_table %>%
  subset(select = c(rideable_type, member_casual)) %>%
  group_by(rideable_type, member_casual) %>%
  summarize(Count = length(rideable_type)) %>%
  filter(rideable_type != "docked_bike")


            ############ Analysis #############


## find avg length of ride and the day of week mode for casual riders
mean(d_ride_table_c$ride_in_seconds)/60 -> avg_ride_length_casual 
getmode(d_ride_table_c$day_of_week) -> mode_dow_c


## find avg length of ride and the day of week mode for members
mean(d_ride_table_m$ride_in_seconds)/60 -> avg_ride_length_member
getmode(d_ride_table_m$day_of_week) -> mode_dow_m


# create data frame for day and ride length information
dow <- c(1,1,2,2,3,3,4,4,5,5,6,6,7,7)
d_avg_ride_by_day <- data.frame(matrix(nrow = length(dow), ncol = 3))
colnames(d_avg_ride_by_day) = c('day', 'ride_length', 'member_type')

d_avg_ride_by_day$day <- dow


## find avg ride length by day for members and store in a table
d_ride_table %>%
  subset(select = c(day_of_week, ride_in_seconds, member_casual)) %>%
  group_by(day_of_week, member_casual) %>%
  summarize(avg_ride = round(mean(ride_in_seconds)/60,
                             digits= 3)) -> a

d_avg_ride_by_day$ride_length <- a$avg_ride 
d_avg_ride_by_day$member_type <- a$member_casual 
head(d_avg_ride_by_day,1)

rm(a)


sm <- -2 #start month
em <- 0 #end month

## loop through filtered tables to find the number of 
## rides in different seasons. increment sm & em by 3 to create
## seasonal ranges
## add the results to the rides_by_season table

#generate empty vectors to fill the columns in rides_by_season table 
season <- c()
ride_count <- c()
member_type <- c()

## Loop to generate values for season, ride_count, and member_type
for (j in 1:4){ #begin for
   
  sm <- sm + 3 ## add 3 to both values to get next season range
  em <- em + 3
  

d_ride_table_c %>%
  filter(month_of_ride >= sm & month_of_ride <= em) %>% ## filter for month range
  summarize(count_r = n()) -> a

ride_count <- append(ride_count, a$count_r) ##append to vectors
season <- append(season, j)
member_type <- append(member_type, 'casual')

d_ride_table_m %>%  
  ## filter for month range
  filter(month_of_ride >= sm & month_of_ride <= em) %>% 
  summarize(count_r = n()) -> b

ride_count <- append(ride_count, b$count_r) ##append to vectors
season <- append(season, j)
member_type <- append(member_type, 'member')
  
  rm(a,b)
  
} # end for

#create new data frame with vectors
d_rides_by_season <- data.frame(season, ride_count, member_type) 

rm(sm,em,j, season, ride_count, member_type)

gc()



            ############ Data Plotting #############


## create theme preset
baseTheme <-   theme_classic() +
  theme(plot.title = element_text(hjust = .5, size = 13, face = 'bold',
                                  family = 'serif'),
        panel.background = element_rect(fill = "#3f403f"),
        plot.background =  element_rect(fill = "#BEBEBE"),
        axis.text.x = element_text(color =  "black", family = 'serif'),
        axis.text.y = element_text(color =  "black", family = 'serif'),
        strip.text = element_text(size = 11, family = 'serif'))

axisScale <- 1000
yScaleMax <- 1000
yScaleMin <- 0
byValue <- 50


## x-axis values for graphs
discreteX <- scale_x_discrete(name = 'day of week',
                 limits = c('mon','tue','wed','thur','fri','sat','sun'))
## y-axis values for graphs
continuousY <-  scale_y_continuous(name = paste("total_rides (",
                                                axisScale, '\'s)'),
                     seq(yScaleMin, yScaleMax,by=byValue),
                     labels = scales::comma)



## Plot member ride count for the last 12 months by weekday
ggplot(d_ride_table,
       aes(x=day_of_week)) +
  ggtitle("Rides by Weekday Monday to Sunday by Membership Type") +
  geom_bar(
    aes(y = after_stat(count)/axisScale),
    fill = '#A1CDF4',
    color = 'black',
    alpha = 0.8) +
  discreteX +
  continuousY +
  geom_text(
    aes(y = after_stat(count)/axisScale, 
        label = round(after_stat(count)/axisScale,1)),
    stat="count", vjust = 1.5, size = 3) +
  facet_wrap(~member_casual) +
  baseTheme


## Plot Average ride length for members and casual riders
d_avg_ride_by_day %>%
  ggplot(aes(x = day, y = ride_length)) +
  ggtitle("Avg Ride Length, Member vs Casual Monday to Sunday") +
  geom_col(position = position_dodge(.9), aes(fill = member_type),
           color = 'grey') +
  discreteX +
  scale_y_continuous(name = "Ride_Length (mins)",
                     seq(0,30,by=5), labels = scales::number) +
  geom_text(aes(label = round(ride_length,2), group = member_type),  
            color = 'black', size = 3, position = position_dodge(0.9),
            vjust = 1.5) +
  scale_fill_brewer(palette = "Paired") +
  baseTheme


##Plot bike type usage for both casual and member riders
rideable_type_count %>%
  ggplot(aes(rideable_type, Count/1000)) +
  ggtitle("Bike Type Usage Member vs Casual") +
  geom_col(position = position_dodge(.8),
           width = .75,
           aes(fill = member_casual), 
           color = 'grey') +
  geom_text(aes(label = round(rideable_type_count$Count/1000, 1), 
                group = member_casual),
            position = position_dodge(.8), vjust = 1.5) +
  xlab('Bike Type') +
  ylab("Ride count (1000's)") +
  scale_fill_brewer(palette = "Paired") +
  baseTheme


##create tables for donut graphs
d_rides_by_season_c <- createDonut(d_rides_by_season, 'casual')
d_rides_by_season_m <- createDonut(d_rides_by_season, 'member')


##create donut graph visual preset
donutTheme <-  theme_void() + 
  theme(plot.title = element_text(hjust = 0.5,size = 20, face = 'bold',
                                  family = 'serif'))+
  theme(plot.background = element_rect(fill = "#f0f0f0") ) +
  theme(legend.position = 'none')


## plot donut graphs for casual riders and members
## for rides per season
ggplot(d_rides_by_season_c, aes(ymax = ymax, ymin = ymin, xmax = 4,
                                xmin =3, fill = season)) +
  ggtitle("Rides by Season Casual") +
  geom_rect()+
  coord_polar(theta = 'y') +
  xlim(c(0.5,4))+
  scale_fill_brewer(palette = "Spectral") +
  geom_text(x=3.5, aes(y = labelPosition, label = season, fontface = 'bold'), size=3) +
  geom_text(x = 4.5, aes(y = labelPosition,
                         label = paste(round(fraction*100, 2), '%'))) +
  
  donutTheme -> g_1 ## assign graph 1
  

ggplot(d_rides_by_season_m, aes(ymax = ymax, ymin = ymin, xmax = 4,
                                xmin =3, fill = season)) +
  ggtitle("Rides by Season Member") +
  geom_rect()+
  coord_polar(theta = 'y') +
  xlim(c(0.5,4))+
  scale_fill_brewer(palette = "Spectral") +
  geom_text(x=3.5, aes(y = labelPosition, label = season, fontface = 'bold'), size=3) +
  geom_text(x = 4.5, aes(y = labelPosition,
                         label = paste(round(fraction*100, 2), '%'))) +
  
  donutTheme -> g_2 ## assign graph 2

  ##combine the donut graphs
  grid.arrange(g_1,  g_2, ncol = 2)

  

            ############ Mapping #############

  ## Create tables for the top ten trips for casual and member riders
top_ten_trips_c <- trip_totals(d_station_trip_totals, 'casual')
top_ten_trips_m <- trip_totals(d_station_trip_totals, 'member')


## using openstreetmap for bounding box info for
## mapping

bbox <- c(left = -87.6597, bottom = 41.8454,right = -87.5931, top = 41.9181)

chicago_map <- get_stamenmap(bbox, zoom = 13, maptype = 'terrain')

gc()


        
        

