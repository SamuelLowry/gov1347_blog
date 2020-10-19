#needed libraries
library(tidyverse)
library(ggthemes)
library(usmap)
library(maptools)
library(janitor)
library(cowplot)

# This week's blog is largely a modification of the lab code applied to Michigan
# loading in csvs and data cleaning
vep_df <- read_csv("data/vep_1980-2016.csv")
pvstate_df    <- read_csv("data/popvote_bystate_1948-2016.csv")
economy_df    <- read_csv("data/econ.csv")
pollstate_df  <- read_csv("data/pollavg_bystate_1968-2016.csv")
poll_pvstate_vep_df <- pvstate_df %>% 
  mutate(D_pv = D/total) %>% 
  inner_join(pollstate_df %>%  filter(weeks_left == 5)) %>% 
  left_join(vep_df)


# VEP used for both 2016 and 2020 due to no 2020 data
VEP_MI <- as.integer(vep_df$VEP[vep_df$state == "Michigan" & vep_df$year == 2016])

#https://public.opendatasoft.com/explore/dataset/usa-2016-presidential-election-by-county/table/?disjunctive.state&sort=-african_american_population
county_df <-read_csv("data/usa-2016-presidential-election-by-county.csv") %>% 
  clean_names() %>% 
  mutate(dem_wm_2012 = democrats_2012 - 50,
         dem_wm_2016 = democrats_2016 - 50)


field_df <- read_csv("data/fieldoffice_2012-2016_byaddress.csv")

# Michigan maps

#obama field office
obama_df <- field_df %>%
  subset(year == 2012 & candidate == "Obama" & state == "MI") %>%
  select(longitude, latitude)

#clinton field office
clinton_df <- field_df %>% 
  subset(year == 2016 & candidate == "Clinton" & state == "MI") %>%
  select(longitude, latitude)

#transform for map
obama_field_transformed_df <- usmap_transform(obama_df)
clinton_field_transformed_df <- usmap_transform(clinton_df)

#clinton and obama map comparison with vote share
plot_usmap(regions = "counties",
           data = county_df,
           values = "dem_wm_2012",
           include = c("MI"))+
  geom_point(data = obama_field_transformed_df,
             aes(x = longitude.1, y = latitude.1),
             color = "green3",
             alpha = 0.75,
             pch=3,
             size=4,
             stroke=2)+
  scale_fill_gradient2(
    high = "blue", mid = "white", low = "red",
    name = "Dem\nwin margin") + 
  labs(title = "Field Offices and Win Margin",
       subtitle = "Obama 2012",
       caption = "Total Field Offices: 28") +
  theme(plot.title = element_text(size = 25, face = "bold")) +
  theme(plot.subtitle = element_text(size = 20)) +
  theme(legend.title = element_text(size = 15),
        legend.text = element_text(size = 10)) +
  theme(plot.caption = element_text(size = 15))

#save plot
ggsave(filename = "figures/obama_mi.png", 
       height = 6,
       width = 6)
#clinton
plot_usmap(regions = "counties", 
           data = county_df, 
           values = "dem_wm_2016",
           include = c("MI"))+
  geom_point(data = clinton_field_transformed_df, 
             aes(x = longitude.1, y = latitude.1), 
             color = "green3", 
             alpha = 0.75, 
             pch=3, 
             size=4, 
             stroke=2)+
  scale_fill_gradient2(
    high = "blue", mid = "white", low = "red",
    name = "Dem\nwin margin") + 
  labs(title = "Field Offices and Win Margin",
       subtitle = "Clinton 2016",
       caption = "Total Field Offices: 27") +
  theme(plot.title = element_text(size = 25, face = "bold", color = "white"),
        plot.subtitle = element_text(size = 20)) +
  theme(legend.title = element_text(size = 15),
        legend.text = element_text(size = 10)) +
  theme(plot.caption = element_text(size = 15))

#save plot
ggsave(filename = "figures/clinton_mi.png",
       height = 6,
       width = 6)



# Simulating a distribution of election results for Michigan 2020
MI_R <- poll_pvstate_vep_df %>%
  filter(state=="Michigan",
         party=="republican") %>% 
  mutate(prob_poll = avg_poll/100)

#sd for poll dist
SD_R <- sd(MI_R$prob_poll)


MI_D <- poll_pvstate_vep_df %>%
  filter(state=="Michigan",
         party=="democrat") %>% 
  mutate(prob_poll = avg_poll/100)

#sd for poll dist
SD_D <- sd(MI_D$prob_poll)

# Trump and Biden models
MI_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, MI_R, family = binomial)
MI_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, MI_D, family = binomial)

# Predictions for both trump and Biden
# https://projects.fivethirtyeight.com/polls/president-general/michigan/
# current numbers from above link
prob_Rvote_MI_2020 <- predict(MI_R_glm, newdata = data.frame(avg_poll = 44.4), type="response")[[1]]
prob_Dvote_MI_2020 <- predict(MI_D_glm, newdata = data.frame(avg_poll = 47.2), type="response")[[1]]

## Get predicted distribution of draws from the population
sim_Rvotes_MI_2020 <- rbinom(n = 10000, size = VEP_MI, prob = rnorm(10000, mean = prob_Rvote_MI_2020, sd = SD_R))
sim_Dvotes_MI_2020 <- rbinom(n = 10000, size = VEP_MI, prob = rnorm(10000, mean = prob_Dvote_MI_2020, sd = SD_D))

## Simulating a distribution of election results
biden_elxns_MI_2020 <- tibble(margin = ((sim_Dvotes_MI_2020-sim_Rvotes_MI_2020)/(sim_Dvotes_MI_2020+sim_Rvotes_MI_2020))*100) %>% 
  mutate(Candidate = "Biden")

#bidens win margin
biden_win <- biden_elxns_MI_2020 %>% 
  summarize(median(margin))

trump_elxns_MI_2020 <- tibble(margin = ((sim_Rvotes_MI_2020-sim_Dvotes_MI_2020)/(sim_Dvotes_MI_2020+sim_Rvotes_MI_2020))*100)  %>% 
  mutate(Candidate = "Trump")

#together for hist
margin_df <- full_join(biden_elxns_MI_2020, trump_elxns_MI_2020)

#histograms of win margins
margin_df %>% 
  ggplot(aes(x = margin,
             fill = Candidate)) +
  geom_histogram(color = 'white',
                 position = "identity",
                 alpha = .7,
                 bins = 20) +
  scale_fill_manual(values = c("blue", "red")) +
  geom_vline(xintercept = as.numeric(biden_win),
             color = "black",
             size = 1.3) +
  scale_y_continuous(trans = "sqrt",
                     breaks = c(0, 100 , 500, 1000, 1500, 2000)) +
  scale_x_continuous(breaks = c(-50, -25, 0, 25, 50)) +
  geom_text(aes(x = 60,
            y = 500, 
            label = "Biden Median: \n 3.4%")) +
  labs(title = "Prediction of Win Margins",
       subtitle = "Michigan 2020 based on March 4 Poll Numbers",
       x = "Win Margin",
       y = "Count",
       caption = "10,000 binomial process simulations") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 25), 
        axis.title.x = element_text(size = 15),
        axis.title.y = element_text(size = 15)) +
  theme(plot.subtitle = element_text(size = 15)) +
  theme(legend.title = element_text(size = 15),
        legend.text = element_text(size = 10)) +
  theme(plot.caption = element_text(size = 10))

#save plot
ggsave("figures/combined_margins.png", height = 5.2, width = 5.2)

#data leaving 2016 out
LOO_MI_R <- poll_pvstate_vep_df %>%
  filter(state == "Michigan",
         party == "republican",
         year != 2016) %>% 
  mutate(prob_poll = avg_poll/100)

#now include sd
LOO_SD_R <- sd(LOO_MI_R$prob_poll)


LOO_MI_D <- poll_pvstate_vep_df %>%
  filter(state=="Michigan",
         party=="democrat",
         year != 2016) %>% 
  mutate(prob_poll = avg_poll/100)

#now include sd
LOO_SD_D <- sd(LOO_MI_D$prob_poll)

# LOO models for 2016 both candidates
LOO_MI_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, LOO_MI_R, family = binomial)
LOO_MI_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, LOO_MI_D, family = binomial)

# Predicted draw probabilities based on LOO models
# 2016 numbers from October 18 of 2016 https://projects.fivethirtyeight.com/2016-election-forecast/michigan/
prob_Rvote_MI_2016 <- predict(LOO_MI_R_glm,
                              newdata = data.frame(avg_poll = 41.3),
                              type = "response")[[1]]
prob_Dvote_MI_2016 <- predict(LOO_MI_D_glm,
                              newdata = data.frame(avg_poll = 50.4),
                              type = "response")[[1]]

# Predicted distributions
sim_Rvotes_MI_2016 <- rbinom(n = 10000, size = VEP_MI, prob = rnorm(n = 10000, mean = prob_Rvote_MI_2016, sd = LOO_SD_R))
sim_Dvotes_MI_2016 <- rbinom(n = 10000, size = VEP_MI, prob = rnorm(n = 10000, mean = prob_Dvote_MI_2016, sd = LOO_SD_D))

# Trump Win Margin
sim_elxns_MI_2016 <- tibble(margin = ((sim_Rvotes_MI_2016-sim_Dvotes_MI_2016)/(sim_Dvotes_MI_2016+sim_Rvotes_MI_2016))*100)
sim_elxns_MI_2016 %>% 
  ggplot(aes(x = margin)) +
  geom_histogram(bins = 20,
                 color = 'white',
                 fill = "red") +
  # .23% actual win margin https://en.wikipedia.org/wiki/2016_United_States_presidential_election_in_Michigan
  geom_text(x = 55,
            y = 1000, 
            label = "Predicted: -8.84% \n Actual : 0.23% \n Chance of Winning: 30.8%") +
  labs(title = "Leave One Out Prediction \n of Trump Win Margin",
       subtitle = "Michigan 2016",
       x = "Win Margin",
       y = "Count",
       caption = "10,000 binomial process simulations") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 15),
        axis.title.y = element_text(size = 15)) +
  theme(plot.subtitle = element_text(size = 15)) +
  theme(plot.caption = element_text(size = 10)) +
  scale_x_continuous(breaks = c(-50, -25, 0, 25, 50))

#save plot
ggsave("figures/updated_LOO_pred.png", height = 6, width = 6)
