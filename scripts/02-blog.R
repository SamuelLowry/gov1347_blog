#needed libraries
library(tidyverse)
library(janitor)
library(usmap)


#loading in csvs and cleaned names
#also got rid of all years that don't have unemployment data
econ_df <- read_csv("data/econ.csv") %>% 
  clean_names() %>% 
  filter(year > 1947)
local_df <- read_csv("data/local.csv") %>% 
  clean_names()
popvote_df <- read_csv("data/popvote_1948-2016.csv") %>% 
  clean_names()
popvotestate_df <- read_csv("data/popvote_bystate_1948-2016.csv") %>% 
  clean_names()

#got state data for unemployment during coronavirus
coronastate_df <- local_df %>% 
  filter(year == 2020) %>% 
  filter(month %in% c("05", "04")) %>% 
  filter(!state_and_area %in% c("Los Angeles County", "New York city")) %>%
  rename(state = state_and_area) %>% 
  group_by(state, year) %>% 
  summarize(unemployment = mean(unemployed_prce)) 

#got national data for unemployment during coronavirus
coronanational_df <- econ_df %>% 
  filter(year == 2020) %>% 
  filter(quarter == 2) %>% 
  select(year, unemployment)

#national econ cleaning
#retrieved election years
#selected needed years and unemploymeny
#dropped na data 
#grouped by year in order to get mean unemployment for election years
econ_df <- econ_df %>% 
  filter(year %in% c(1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020)) %>% 
  select(year, unemployment) %>% 
  drop_na() %>% 
  group_by(year) %>% 
  summarize(unemployment = mean(unemployment))

#in order to get incumbent joined national popvote with unemployment
nationalcombined_df <- econ_df %>% 
  full_join(popvote_df, by = "year") %>%
  filter(incumbent_party == TRUE) %>% 
  rename(vote = pv2p) 

#got unemployment for 2020, including pre corona 
national2020_df <- econ_df %>% 
  filter(year == 2020)

#national model using unemployment to predict incumbent vote share
national_model <- lm(data = nationalcombined_df, vote ~ unemployment)

#using the model to predict 2020 in total but then also for coronavirus time
prediction_national <- predict(national_model, national2020_df)
prediction_corona_national <- predict(national_model, coronanational_df)

#ggplot depicting relationship between unemployment and incumbent vote
nationalcombined_df %>% 
  ggplot(aes(x = unemployment, y = vote)) +
  geom_point() +
  geom_smooth(method = 'lm', se = FALSE) +
  geom_text(aes(label = year), hjust = .02) +
  #xlim just so that 2012 doesnt get cut off
  xlim(3, 8.3) +
  labs(title = "Incumbent Party Vote and Election Year Unemployment",
       subtitle = "In the Presidential Election",
       x = "Election Year Unemployment Rate",
       y = "Incumbent Party Percent of Two Party Vote") +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/national.png")
  
#cleaning local_df
#used below to figure out what areas would technically be double counted for the vote
#unique(local_df$state_and_area) 
local_df <- local_df %>% 
  filter(!state_and_area %in% c("Los Angeles County", "New York city")) %>% 
  group_by(state_and_area, year) %>% 
  drop_na() %>% 
  summarize(unemployment = mean(unemployed_prce)) %>% 
  rename(state = state_and_area)

#state unemployment pre corona inclusive
local2020_df <- local_df %>% 
  filter(year == 2020) 
  
#select election years for state
local_df <- local_df %>% 
  filter(year %in% c(1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016))

# in order to get incumbent vote share in comparison to unemployment joined the data frames
# only incumbent vote
# select for their vote
# mutate to get incumbent vote based upon its two party share
#select for the needed columns 
statecombined_df <- popvote_df %>% 
  right_join(popvotestate_df, by = "year") %>%
  filter(incumbent_party == TRUE) %>% 
  select(year, party, state, r_pv2p, d_pv2p) %>% 
  left_join(local_df, by = c("state", "year")) %>% 
  filter(year > 1975) %>% 
  mutate(vote = case_when(
    party == "republican" ~ r_pv2p,
    party == "democrat" ~ d_pv2p)) %>% 
  select(year, state, unemployment, vote)

#state model using unemployment to predict incumbent vote
state_model <- statecombined_df %>% 
  group_by(state) %>% 
  nest() %>% 
  mutate(models = map(data, ~lm(vote ~ unemployment, data = .x))) %>% 
  mutate(coefs = map(models, ~coef(.x))) %>% 
  mutate(intercept = map_dbl(coefs, ~pluck(.x, "(Intercept)"))) %>% 
  mutate(slope = map_dbl(coefs, ~pluck(.x, "unemployment"))) %>% 
  select(state, intercept, slope)

#prediction data frame based upon pre corona too
statepred_df <- state_model %>% 
  right_join(local2020_df) %>% 
  mutate(pred = intercept + slope*unemployment) %>% 
  mutate(win = ifelse(pred > 50, "Trump", "Biden"))

#prediction data frame based upon pre corona too
coronastatepred_df <- state_model %>% 
  right_join(coronastate_df) %>% 
  mutate(pred = intercept + slope*unemployment) %>% 
  mutate(win = ifelse(pred > 50, "Trump", "Biden"))

#Shapefile of states from usmap library
states_map <- usmap::us_map()

#prediction map with all 2020 data
plot_usmap(data = statepred_df,regions = "states", values = "win", color = "white") +
  scale_fill_manual(values = c("blue", "red"), name = "Predicted Outcome") +
  labs(title = "Using Unemployment to Predict 2020 Election",
       subtitle = "Based on 2020 average unemployment") +
  theme_void() +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/state.png", height = 4, width = 6)

#prediction map for corona
plot_usmap(data = coronastatepred_df,regions = "states", values = "win", color = "white") +
  scale_fill_manual(values = c("blue", "red"), name = "Predicted Outcome") +
  labs(title = "Using Unemployment to Predict 2020 Election",
       subtitle = "Based on COVID-19 unemployment") +
  theme_void() +
  theme(plot.title = element_text(face = "bold"))

#ggsave as a png for my md
ggsave("figures/corona.png", height = 4, width = 6)
