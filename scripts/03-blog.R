#needed libraries
library(tidyverse)
library(janitor)
library(usmap)
library(ggthemes)
library(cowplot)


#loading in csvs and cleaned names
econ_df <- read_csv("data/econ.csv") %>% 
  clean_names() 
popvote_df <- read_csv("data/popvote_1948-2016.csv") %>% 
  clean_names()
polls_2016_df <- read_csv("data/polls_2016.csv")
polls_2020_df <- read_csv("data/polls_2020.csv")

#pollster grade data from 538, cleaned up and factored correctly
grade_16_df <- read_csv("https://raw.githubusercontent.com/fivethirtyeight/data/master/pollster-ratings/2016/pollster-ratings.csv") %>% 
  clean_names() %>%
  mutate(x538_grade = factor(x538_grade,
                             levels = c("A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"))) %>% 
  drop_na(x538_grade)

#pollster grade data from 538, cleaned up and factored correctly, had to rename certain things due to an odd character
grade_20_df <- read_csv("https://raw.githubusercontent.com/fivethirtyeight/data/master/pollster-ratings/2019/pollster-ratings.csv") %>% 
  clean_names() %>%
  mutate(x538_grade = case_when(x538_grade ==  "A/B°" ~ "A/B",
                                x538_grade ==  "B/C°" ~ "B/C",
                                x538_grade ==  "C/D°" ~ "C/D",
                                TRUE ~ x538_grade)) %>% 
  mutate(x538_grade = factor(x538_grade,
                             levels = c("A+", "A", "A-", "A/B", "B+", "B", "B-", "B/C", "C+", "C", "C-", "C/D", "D", "F"))) %>% 
  drop_na(x538_grade)

#grade plots
grade_16_plot <- grade_16_df %>% 
  ggplot(aes(x = x538_grade)) +
  geom_bar(fill = 'darkblue') +
  theme_minimal() +
  labs(title = "Pollster Grade 2016",
       x = "Grade",
       y = "Count",
       caption = "Source: FiveThirtyEight")

grade_20_plot <- grade_20_df %>% 
  ggplot(aes(x = x538_grade)) +
  geom_bar(fill = 'darkblue') +
  theme_minimal() +
  labs(title = "Pollster Grade 2020",
       x = "Grade",
       y = "Count",
       caption = "Source: FiveThirtyEight")

#put them together
plot_grid(grade_16_plot, grade_20_plot)

#saved for blog
ggsave("figures/grade_plot.png", height = 6, width = 12)
  
  

#segmented data for the challenger for fundamentals model
chal_fund_df <- econ_df %>% 
  filter(quarter == 2) %>% 
  right_join(popvote_df, by = c("year")) %>% 
  filter(incumbent_party == FALSE,
         incumbent == FALSE)

#segmented data for the incumbent for fundamentals model
inc_fund_df <- econ_df %>% 
  filter(quarter == 2) %>% 
  right_join(popvote_df, by = c("year")) %>% 
  filter(incumbent_party == TRUE,
         incumbent == TRUE)

#plots showing model based off of second quarter gdp growth for both the challenger and the incumbent
chal_plot <- chal_fund_df %>% 
  ggplot(aes(x = gdp_growth_qt, y = pv)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = year)) +
  geom_smooth(method = 'lm', 
              se = FALSE) +
  theme_minimal() +
  labs(title = "Fundamentals Model for the Challenger",
       x = "Percent Second Quarter GDP Growth",
       y = "Percent of Popular Vote")

inc_plot <- inc_fund_df %>% 
  ggplot(aes(x = gdp_growth_qt, y = pv)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = year)) +
  geom_smooth(method = 'lm', 
              se = FALSE) +
  theme_minimal() +
  labs(title = "Fundamentals Model for the Incumbent",
       x = "Percent Second Quarter GDP Growth",
       y = "Percent of Popular Vote")

#put them together
plot_grid(inc_plot, chal_plot)

#saved for blog
ggsave("figures/fund_plot.png", height = 6, width = 12)
