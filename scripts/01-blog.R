#Required Libraries
library(tidyverse)
library(usmap)
library(ggplot2)

#Read in the data with proper column specification in order to avoid an error.
popvote_state_df <- read_csv("data/popvote_bystate_1948-2016.csv",
                       col_types = cols(
                         state = col_character(),
                         year = col_double(),
                         total = col_double(),
                         D = col_double(),
                         R = col_double(),
                         R_pv2p = col_double(),
                         D_pv2p = col_double()
                       ))

#Created the swing state data using a series of ifelses and then plugging the years and previous election's data into the equation
#Cut off 1948 election due to nothing being before it
swing_df <- popvote_state_df %>% 
  group_by(state) %>% 
  arrange(year) %>% 
  mutate(D_p = if_else(state == lag(state),
                      lag(D),
                      0)) %>%
  mutate(R_p = if_else(state == lag(state),
                       lag(R),
                       0)) %>% 
  mutate(swing = (D/(D+R))-(D_p/(D_p+R_p))) %>% 
  filter(year > 1948)

#Filter by year to make two separate graphics
swing1_df <- swing_df %>% 
  filter(year < 1980)

swing2_df <- swing_df %>% 
  filter(year > 1976)

#Shapefile of states from usmap library
states_map <- usmap::us_map()

#Plot showing the change in proportion of the state voting blue
#faceted by year
plot_usmap(data = swing1_df, regions = "states", values = "swing") +
  scale_fill_gradient2(
    low = "red", 
    mid = "white",
    high = "blue",
    name = "Vote Swing") +
  facet_wrap(facets = year ~.) +
  labs(title = "Change in Proportion of Presidential Popular Vote",
       subtitle = "For the Democratic candidate in comparison to the previous election (1952-1976)",
       caption = "*Gray states denote missing data") +
  theme_void() +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/swing1.png")

#Plot showing the change in proportion of the state voting blue
#faceted by year
plot_usmap(data = swing2_df, regions = "states", values = "swing") +
  scale_fill_gradient2(
    low = "red", 
    mid = "white",
    high = "blue",
    name = "Vote Swing") +
  facet_wrap(facets = year ~.) +
  labs(title = "Change in Proportion of Presidential Popular Vote",
       subtitle = "For the Democratic candidate in comparison to the previous election (1980-2016)") +
  theme_void() +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/swing2.png")

#Created a column which returns if a state flipped or stayed the same
flip_df <- swing_df %>%
  mutate(winner = ifelse(R > D, "republican", "democrat")) %>% 
  mutate(winner_p = ifelse(R_p > D_p, "republican", "democrat")) %>% 
  mutate(flip = case_when(
    winner == winner_p ~ "No Change",
    winner == "republican" & winner_p == "democrat" ~ "Flipped R",
    winner == "democrat" & winner_p == "republican" ~ "Flipped D")) %>% 
  replace_na(list(flip = "No Data"))

#Filter by year to make two separate graphics
flip1_df <- flip_df %>% 
  filter(year < 1980)

flip2_df <- flip_df %>% 
  filter(year > 1976)

#Plot showing if a state flipped or not
#faceted by year
plot_usmap(data = flip1_df, regions = "states", values = "flip", color = "white") +
  facet_wrap(facets = year ~.) +
  scale_fill_manual(values = c("blue", "red", "gray", "black"), name = "Election Outcome") +
  labs(title = "States which Flipped in the Presidential Election",
       subtitle = "1952-1976") +
  theme_void() +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/flip1.png")

#Plot showing if a state flipped or not
#faceted by year
  plot_usmap(data = flip2_df,regions = "states", values = "flip", color = "white") +
  facet_wrap(facets = year ~.) +
  scale_fill_manual(values = c("blue", "red", "gray"), name = "Election Outcome") +
  labs(title = "States which Flipped in the Presidential Election",
       subtitle = "1980-2016") +
  theme_void() +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/flip2.png")

#figuring out what states flipped the most
mostflips_df <- flip_df %>% 
  filter(flip %in% c("Flipped R", "Flipped D")) %>% 
  group_by(state) %>% 
  summarize(flips = n()) %>% 
  arrange(desc(flips))
