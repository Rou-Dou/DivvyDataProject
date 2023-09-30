## Map start/end station locations for the top 10 trips taken by members
ggmap(chicago_map) +
  geom_point(data = top_ten_trips_m
             ,aes(x = lon.x, y=lat.x),size = 3)+
  geom_point(data = top_ten_trips_m,
             aes(x = lon.y, y = lat.y),size =3)+
  theme(legend.position = "none")