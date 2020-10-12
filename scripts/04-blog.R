#needed libraries
library(tidyverse)
library(janitor)
library(usmap)
library(ggthemes)
library(cowplot)
library(lubridate)
library(survey)
library(gt)
library(stringr)
library(readxl)

#loading in csvs and cleaned names
econ_df <- read_csv("data/econ.csv") %>% 
  clean_names() 
popvote_df <- read_csv("data/popvote_1948-2016.csv") %>% 
  clean_names()

#had to change states to abbreviations
popvotestate_df <- read_csv("data/popvote_bystate_1948-2016.csv") %>% 
  mutate(state = state.abb[match(state,state.name)])

#change column name for merges
grants_df <- read_csv("data/fedgrants_bystate_1988-2008.csv") %>% 
  rename(state = state_abb)

#pivot for row with every year and state 
#format state names to abbreviations
#https://www.kaggle.com/hassenmorad/historical-state-populations-19002017 data from here
statepops_df <- read_csv("data/state_pops.csv") %>% 
  clean_names() %>% 
  pivot_longer(cols = !year) %>% 
  rename(state = name,
         pop_mil = value) %>%
  mutate(state = str_to_title(state)) %>% 
  mutate(state = state.abb[match(state,state.name)])

#Data for Q2 numbers
fund_df <- econ_df %>% 
  filter(quarter == 2) %>% 
  right_join(popvote_df, by = c("year")) %>% 
  mutate(incumbent = ifelse(incumbent == TRUE, "Incumbent", "Challenger"),
         incumbent = factor(incumbent,
                            levels = c("Incumbent", "Challenger")))
#plot for GDP's affect
fund_df %>% 
  ggplot(aes(x = gdp_growth_qt, y = pv)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = year)) +
  geom_smooth(method = 'lm', 
              se = FALSE,
              color = "darkblue") +
  theme_minimal() +
  labs(title = "Association with GDP Growth",
       x = "Percent Second Quarter GDP Growth",
       y = "Percent of Popular Vote") +
  theme(plot.title = element_text(face = "bold", size = 30), 
        axis.title.x = element_text(size = 20),
        axis.title.y = element_text(size = 20)) +
  facet_wrap(~ incumbent)

#saved for blog
ggsave("figures/gdp_plot.png", height = 6, width = 12)

#plot for unemployment's affect
fund_df %>% 
  ggplot(aes(x = unemployment, y = pv)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = year)) +
  geom_smooth(method = 'lm', 
              se = FALSE,
              color = "darkblue") +
  theme_minimal() +
  labs(title = "Association with Unemployment",
       x = "Second Quarter Unemployment Rate",
       y = "Percent of Popular Vote") +
  theme(plot.title = element_text(face = "bold", size = 30), 
        axis.title.x = element_text(size = 20),
        axis.title.y = element_text(size = 20)) +
  facet_wrap(~ incumbent)

#saved for blog
ggsave("figures/unemployment_plot.png", height = 6, width = 12)


#data cleaning for grant df
grants_df <- grants_df %>%
  left_join(statepops_df) %>% 
  #normalized for population
  mutate(grant_percap = grant_mil/pop_mil) %>% 
  drop_na(grant_percap) %>%
  filter(year > 1984) %>% 
  #for getting average per term
  mutate(term = case_when(year %in% c(1985, 1986, 1987, 1988) ~ 1988,
                          year %in% c(1989, 1990, 1991, 1992) ~ 1992,
                          year %in% c(1993, 1994, 1995, 1996) ~ 1996,
                          year %in% c(1997, 1998, 1999, 2000) ~ 2000,
                          year %in% c(2001, 2002, 2003, 2004) ~ 2004,
                          year %in% c(2005, 2006, 2007, 2008) ~ 2008
  )) %>% 
  group_by(state, term) %>% 
  #average per term
  summarize(average_grant = mean(grant_percap)) %>% 
  rename(year = term) %>% 
  #percent change per term
  mutate(prior_term = if_else(state == lag(state),
                              lag(average_grant),
                              0)) %>% 
  mutate(change = ((average_grant - prior_term)/prior_term)*100) %>% 
  #add in voting data
  left_join(popvotestate_df) %>% 
  #add in candidate data
  left_join(popvote_df) %>% 
  select(-pv, -pv2p) %>% 
  #get correct vote number
  mutate(pv2p = ifelse(party == "democrat", D_pv2p, R_pv2p)) %>% 
  mutate(incumbent = ifelse(incumbent == TRUE, "Incumbent", "Challenger"),
         incumbent = factor(incumbent,
                            levels = c("Incumbent", "Challenger"))) %>% 
  #make id column with state and year for plot
  mutate(year = as.character(str_sub(year, start = 3, end = 4)),
         id = str_c(state, year, sep = " '"))

#plot for change in grants
grants_df %>% 
  ggplot(aes(x = change, y = pv2p)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = id)) +
  geom_smooth(method = 'lm', 
              se = FALSE,
              color = "darkblue") +
  theme_minimal() +
  labs(title = "Association with Change in Grant Spending",
       x = "Percent Change in Federal Grant Spending",
       y = "Percent of Two Party Vote Share") +
  theme(plot.title = element_text(face = "bold", size = 30), 
        axis.title.x = element_text(size = 20),
        axis.title.y = element_text(size = 20)) +
  facet_wrap(~ incumbent)

#saved for blog
ggsave("figures/grants_plot.png", height = 6, width = 12)

#read in covid funds data
#taggs.hhs.gov/coronavirus
covid_df <- read_xlsx("data/GridExport_010_04_2020.xlsx") %>% 
  clean_names()

#2020 state pop data for normalization
#https://worldpopulationreview.com/states
pop2020_df <- read_csv("data/csvData.csv") %>% 
  clean_names() %>% 
  select(state, pop)

#combining the two for a normalized figure
map_df <- covid_df %>% 
  left_join(pop2020_df) %>% 
  mutate(award_percap = total/pop) %>% 
  drop_na(pop) %>% 
  filter(state != "District of Columbia")

## shapefile of states from `usmap` library
states_map <- usmap::us_map()
unique(states_map$abbr)

#map showing covid aid 
plot_usmap(data = map_df, regions = "states", values = "award_percap") +
  #because Alaska is such an outlier, scale log 10 to show contrast
  scale_fill_gradient(low = "white", high = "red", name = "Award Per Capita", trans = 'log10') +
  theme_void() +
  labs(title = "Total COVID-19 Related Grants Per Capita") +
  theme(plot.title = element_text(face = "bold", size = 30))

#save the map
ggsave("figures/grant_map.png", height = 6, width = 10)

#model with confidence intervals, fundamentals
gdp_model <- lm(formula = pv ~ gdp_growth_qt*incumbent, data = fund_df)
unemployment_model <- lm(formula = pv ~ unemployment*incumbent, data = fund_df)

#2020 candidates
cand_df <- tibble(candidate = c("Trump", "Biden"),
                  incumbent = c("Incumbent", "Challenger")) %>% 
  mutate(year = 2020) 

#2020 economic data
corona_df <- econ_df %>% 
  filter(quarter == 2,
         year == 2020) %>% 
  left_join(cand_df) %>% 
  mutate(incumbent = factor(incumbent,
                            levels = c("Incumbent", "Challenger")))

#predition and formatting
fund_pred <- as.data.frame(predict(gdp_model, corona_df,
                                         interval = "prediction", 
                                         level = 0.95)) %>% 
  rbind(as.data.frame(predict(unemployment_model, corona_df,
                              interval = "prediction", 
                              level=0.95))) %>% 
  mutate(Model = c("GDP", "GDP", "Unemployment", "Unemployment")) %>% 
  mutate(Candidate = c("Trump", "Biden", "Trump", "Biden")) %>% 
  rename(Point = fit,
         Upper = upr,
         Lower = lwr)

#reordered columns using this link for reference http://www.sthda.com/english/wiki/reordering-data-frame-columns-in-r
fund_pred <- fund_pred[, c(5, 4, 1, 2, 3)] 

#made estimate gt table using this link for reference https://gt.rstudio.com/articles/intro-creating-gt-tables.html
estimate_table <- fund_pred %>% 
  gt() %>% 
  tab_header(
    title = "Percent of Populate Vote Estimates",
    subtitle = "2020 Presidential Election") %>% 
  tab_source_note(source_note = md("Showing 95% confidence intervals")) %>% 
  #formatted numbers using this link https://gt.rstudio.com/reference/fmt_number.html
  fmt_number(decimals = 2,
             columns = 3:5)
estimate_table
