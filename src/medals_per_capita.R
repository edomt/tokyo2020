library(lubridate)
library(data.table)
library(rvest)
library(plyr)
options(scipen = 999)

url <- "https://olympics.com/tokyo-2020/olympic-games/en/results/all-sports/medal-standings.htm"

df <- read_html(url) %>%
  html_node("#medal-standing-table") %>%
  html_table() %>%
  data.table()

mapping <- fread("input/country_mapping.csv")

df[, entity := mapvalues(`Team/NOC`, mapping$from, mapping$to)]

pop <- fread("input/population.csv")

df <- merge(df, pop, by = "entity", all.x = TRUE)
stopifnot(all(!is.na(df$population)))

df[, medals_per_million := round(1e6 * Total / population, 4)]
setorder(df, -medals_per_million)

df <- df[, c("entity", "Total", "population", "medals_per_million")]
setnames(df, "Total", "medals")
df <- df[, last_updated := today()]

fwrite(df, "output/medals_per_million.csv")
