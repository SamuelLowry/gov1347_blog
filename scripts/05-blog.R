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


# This week's blog is largely a modification of the lab code applied to Michigan
# loading in csvs and data cleaning
vep_df <- read_csv("data/vep_1980-2016.csv")
pvstate_df    <- read_csv("data/popvote_bystate_1948-2016.csv")
economy_df    <- read_csv("data/econ.csv")
pollstate_df  <- read_csv("data/pollavg_bystate_1968-2016.csv")
ad_df <- read_csv("data/ads_2020.csv") %>% 
  filter(state == "MI") %>% 
  summarize(biden_airings = sum(biden_airings),
            trump_airings = sum(trump_airings),
            total_airings = sum(total_airings),
            total_cost = sum(total_cost))

poll_pvstate_vep_df <- pvstate_df %>% 
  mutate(D_pv = D/total) %>% 
  inner_join(pollstate_df %>%  filter(weeks_left == 5)) %>% 
  left_join(vep_df)


#Leave one out validation of the polling model
#2016 doesnt look too hot

# VEP used for both 2016 and 2020 due to no 2020 data
VEP_MI <- as.integer(vep_df$VEP[vep_df$state == "Michigan" & vep_df$year == 2016])

#data leaving 2016 out
LOO_MI_R <- poll_pvstate_vep_df %>%
  filter(state == "Michigan",
         party == "republican",
         year != 2016)
LOO_MI_D <- poll_pvstate_vep_df %>%
  filter(state=="Michigan",
         party=="democrat",
         year != 2016)

# LOO models for 2016 both candidates
LOO_MI_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, LOO_MI_R, family = binomial)
LOO_MI_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, LOO_MI_D, family = binomial)

# Predicted draw probabilities based on LOO models
# 2016 numbers from October 11 of 2016 https://projects.fivethirtyeight.com/2016-election-forecast/michigan/
prob_Rvote_MI_2016 <- predict(LOO_MI_R_glm,
                              newdata = data.frame(avg_poll = 41.7),
                              type = "response")[[1]]
prob_Dvote_MI_2016 <- predict(LOO_MI_D_glm,
                              newdata = data.frame(avg_poll = 50),
                              type = "response")[[1]]

# Predicted distributions
sim_Rvotes_MI_2016 <- rbinom(n = 10000, size = VEP_MI, prob = prob_Rvote_MI_2016)
sim_Dvotes_MI_2016 <- rbinom(n = 10000, size = VEP_MI, prob = prob_Dvote_MI_2016)

# Trump Win Margin
sim_elxns_MI_2016 <- tibble(margin = ((sim_Rvotes_MI_2016-sim_Dvotes_MI_2016)/(sim_Dvotes_MI_2016+sim_Rvotes_MI_2016))*100)
sim_elxns_MI_2016 %>% 
  ggplot(aes(x = margin)) +
  geom_histogram(bins = 15,
                 color = 'white',
                 fill = "darkblue") +
  # .23% actual win margin https://en.wikipedia.org/wiki/2016_United_States_presidential_election_in_Michigan
  geom_text(x = -8.08,
            y = 1000, 
            label = "Actual Win Margin: 0.23") +
  labs(title = "Leave One Out Prediction \n of Trump Win Margin",
       subtitle = "Michigan 2016",
       x = "Win Margin",
       y = "Count",
       caption = "10,000 binomial process simulations") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 15),
        axis.title.y = element_text(size = 15))

#save plot
ggsave("figures/LOO_pred.png", height = 5, width = 5)

# Simulating a distribution of election results for Michigan 2020
MI_R <- poll_pvstate_vep_df %>%
  filter(state=="Michigan",
         party=="republican")
MI_D <- poll_pvstate_vep_df %>%
  filter(state=="Michigan",
         party=="democrat")

# Trump and Biden models
MI_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, MI_R, family = binomial)
MI_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, MI_D, family = binomial)

# Predictions for both trump and Biden
# https://projects.fivethirtyeight.com/polls/president-general/michigan/
# current numbers from above link
prob_Rvote_MI_2020 <- predict(MI_R_glm, newdata = data.frame(avg_poll = 43.2), type="response")[[1]]
prob_Dvote_MI_2020 <- predict(MI_D_glm, newdata = data.frame(avg_poll = 51.2), type="response")[[1]]

## Get predicted distribution of draws from the population
sim_Rvotes_MI_2020 <- rbinom(n = 10000, size = VEP_MI, prob = prob_Rvote_MI_2020)
sim_Dvotes_MI_2020 <- rbinom(n = 10000, size = VEP_MI, prob = prob_Dvote_MI_2020)

## Simulating a distribution of election results: Biden win margin
sim_elxns_MI_2020 <- tibble(margin = ((sim_Rvotes_MI_2020-sim_Dvotes_MI_2020)/(sim_Dvotes_MI_2020+sim_Rvotes_MI_2020))*100)
sim_elxns_MI_2020 %>% 
  ggplot(aes(x = margin)) +
  geom_histogram(bins = 15,
                 color = 'white',
                 fill = "darkblue") +
  geom_vline(xintercept = (as.numeric(sim_elxns_MI_2020 %>% summarize(median(margin)))),
             color = "darkred",
             size = 1, ) +
  labs(title = "Prediction of Trump Win Margin",
       subtitle = "Michigan 2020",
       x = "Win Margin",
       y = "Count",
       caption = "10,000 binomial process simulations") +
  geom_text(x = -6.84,
            y = 1000, 
            label = "Median: -6.92",
            color = "darkred") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 15),
        axis.title.y = element_text(size = 15))

#save plot
ggsave("figures/poll_pred.png", height = 5, width = 5)


# Requirement for Change 

#hypothetical addition of 6.92% using gerber's numbers
change_primary_df <- tibble(margin = ((sim_Rvotes_MI_2020-sim_Dvotes_MI_2020)/(sim_Dvotes_MI_2020+sim_Rvotes_MI_2020))*100 + rnorm(10000, 6.92, 1.5)) %>% 
  mutate(ads = "With")

#normal prediction for comparison
change_intermediate_df <- sim_elxns_MI_2020 %>% 
  mutate(ads = "Without") 

#joined actual and hypothetical
change_final_df <- full_join(change_primary_df, change_intermediate_df)

#plot of group with ads and without ads
change_final_df %>% 
  ggplot(aes(x = margin, fill = ads)) +
  geom_histogram(bins = 50,
                 color = 'white') +
  #scale needed due to vast difference in distribution shape
  scale_y_continuous(trans = "log10") +
  #1384 due to being equal to number needed to make election a coin toss per gerber
  labs(title = "Estimated Effect of 1,384 GRPs",
       subtitle = "Trump Win Margin (Michigan 2020)",
       x = "Win Margin",
       y = "Count",
       caption = "10,000 binomial process simulations",
       fill = "Additional Ads") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 15),
        axis.title.y = element_text(size = 15)) +
  scale_fill_manual(values = c("darkblue", "darkred"))

#save plot
ggsave("figures/gerber.png", height = 5, width = 5)


# Plot of airings 

#average cost of ad
avg_cost <- ad_df$total_cost / ad_df$total_airings

#pivoting for ggplot
ad_df <- ad_df %>% 
  select(biden_airings, trump_airings) %>% 
  pivot_longer(cols = everything()) %>% 
  mutate(name = if_else(name == "biden_airings", "Biden Airings", "Trump Airings"))

#plot of airings 
ad_df %>% 
  ggplot(aes(x = name, y = value, fill = name)) +
  geom_col(width = 0.5) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 15),
        axis.title.y = element_text(size = 15), 
        legend.position = "none") +
  labs(title = "Total Airings of Ads in Michigan",
       subtitle = "To date for the 2020 Presidential Election",
       x = "Total Airings",
       y = "Count") +
  scale_fill_manual(values = c("darkblue", "darkred"))

#save plot
ggsave("figures/ads.png", height = 5, width = 5)

