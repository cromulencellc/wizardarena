scores <- read.table("../tmp/time_series_score.csv", header=T, sep=",")
ggplot(data=scores, aes(x=round_id, y=sum, group=name, colour=name)) +
  geom_line() +
  scale_colour_hue()
