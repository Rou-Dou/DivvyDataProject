## Map all stations within the bounds of the top 10         
ggmap(chicago_map) +
  geom_point(data = r_station_lat_lng, aes(x = lon, y = lat))
