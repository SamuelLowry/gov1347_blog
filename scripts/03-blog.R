#needed libraries
library(tidyverse)
library(janitor)
library(usmap)
library(ggthemes)
library(cowplot)
library(lubridate)
library(survey)
library(gt)

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
#formatted to actually be readable on website
grade_16_plot <- grade_16_df %>% 
  ggplot(aes(x = x538_grade)) +
  geom_bar(fill = 'darkblue') +
  theme_minimal() +
  labs(title = "Pollster Grades 2016",
       x = "Grade",
       y = "Count",
       caption = "Source: FiveThirtyEight") +
  theme(plot.title = element_text(face = "bold", size = 24), 
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16))

#grade plots
#formatted to actually be readable on website
grade_20_plot <- grade_20_df %>% 
  ggplot(aes(x = x538_grade)) +
  geom_bar(fill = 'darkblue') +
  theme_minimal() +
  labs(title = "Pollster Grades 2020",
       x = "Grade",
       y = "Count",
       caption = "Source: FiveThirtyEight") +
  theme(plot.title = element_text(face = "bold", size = 24), 
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16))

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

#plots showing model based off of second quarter gdp growth for the challenger
chal_plot <- chal_fund_df %>% 
  ggplot(aes(x = gdp_growth_qt, y = pv)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = year)) +
  geom_smooth(method = 'lm', 
              se = FALSE,
              color = "darkblue") +
  theme_minimal() +
  labs(title = "Fundamentals Model for the Challenger",
       x = "Percent Second Quarter GDP Growth",
       y = "Percent of Popular Vote") +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16))

#plots showing model based off of second quarter gdp growth for the incumbent
inc_plot <- inc_fund_df %>% 
  ggplot(aes(x = gdp_growth_qt, y = pv)) +
  geom_point(alpha = 0) +
  geom_text(aes(label = year)) +
  geom_smooth(method = 'lm', 
              se = FALSE,
              color = "darkblue") +
  theme_minimal() +
  labs(title = "Fundamentals Model for the Incumbent",
       x = "Percent Second Quarter GDP Growth",
       y = "Percent of Popular Vote") +
  theme(plot.title = element_text(face = "bold", size = 20), 
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16))

#put them together
plot_grid(inc_plot, chal_plot)

#saved for blog
ggsave("figures/fund_plot.png", height = 6, width = 12)

#plot showing september 2020 polls
recent_poll_plot <- polls_2020_df %>% 
  filter(stage == "general",
         candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  filter(is.na(state)) %>% 
  drop_na(fte_grade) %>% 
  filter(fte_grade != c("D", "F")) %>% 
  mutate(weight = case_when(fte_grade %in% c("A+", "A", "A-", "A/B") ~ 3,
                            fte_grade %in% c("B+", "B", "B-", "B/C") ~ 2,
                            fte_grade %in% c("C+", "C", "C-", "C/D") ~ 1)) %>% 
  mutate(end_date = mdy(end_date),
         election_date = mdy(election_date)) %>% 
  mutate(days_out = as.duration(interval(end_date, election_date)) / (60*60*24)) %>% 
  filter(days_out <= 59) %>% 
  ggplot(aes(x = end_date, y = pct, color = candidate_name)) +
  geom_jitter() +
  geom_smooth(method = 'lm', se = FALSE) +
  scale_color_manual(values=c("darkred", "darkblue")) +
  theme_minimal() +
  labs(title = "Presidential Election Polls",
       subtitle = "From September 2020",
       x = "Date",
       y = "Percent",
       color = "Candidate") +
  theme(plot.title = element_text(face = "bold", size = 24),
        plot.subtitle = element_text(size = 20),
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16))

#plot showing a polls back a year before the election
old_poll_plot <- polls_2020_df %>% 
  filter(stage == "general",
         candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  filter(is.na(state)) %>% 
  drop_na(fte_grade) %>% 
  filter(fte_grade != c("D", "F")) %>% 
  mutate(weight = case_when(fte_grade %in% c("A+", "A", "A-", "A/B") ~ 3,
                            fte_grade %in% c("B+", "B", "B-", "B/C") ~ 2,
                            fte_grade %in% c("C+", "C", "C-", "C/D") ~ 1)) %>% 
  mutate(end_date = mdy(end_date),
         election_date = mdy(election_date)) %>% 
  mutate(days_out = as.duration(interval(end_date, election_date)) / (60*60*24)) %>% 
  filter(days_out <= 365) %>% 
  ggplot(aes(x = end_date, y = pct, color = candidate_name)) +
  geom_jitter() +
  geom_smooth(method = 'lm', se = FALSE) +
  scale_color_manual(values=c("darkred", "darkblue")) +
  theme_minimal() +
  labs(title = "Presidential Election Polls",
       subtitle = "From a year out",
       x = "Month",
       y = "Percent",
       color = "Candidate") +
  theme(plot.title = element_text(face = "bold", size = 24),
        plot.subtitle = element_text(size = 20),
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16))

#Put them together
plot_grid(old_poll_plot, recent_poll_plot)

#saved for blog
ggsave("figures/poll_comp_plot.png", height = 6, width = 12)

poll_pred_df <- polls_2020_df %>% 
  filter(stage == "general",
         candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  filter(is.na(state)) %>% 
  drop_na(fte_grade) %>% 
  filter(fte_grade != c("D", "F")) %>% 
  mutate(weight = case_when(fte_grade %in% c("A+", "A", "A-", "A/B") ~ 3,
                            fte_grade %in% c("B+", "B", "B-", "B/C") ~ 2,
                            fte_grade %in% c("C+", "C", "C-", "C/D") ~ 1)) %>% 
  mutate(end_date = mdy(end_date),
         election_date = mdy(election_date)) %>% 
  mutate(days_out = as.duration(interval(end_date, election_date)) / (60*60*24)) %>% 
  filter(days_out <= 59) %>%
  mutate(weighted_pct = (weight/sum(weight) * pct)) %>%
  group_by(candidate_name) %>%
  summarize(sum = sum(weighted_pct * 2))

#dataframe needed with q2 growth from 2020
corona_df <- econ_df %>% 
  filter(year == 2020,
         quarter == 2) %>% 
  select(gdp_growth_qt)

#model for trump with confidence intervals, fundamentals
inc_fund_model <- lm(formula = pv ~ gdp_growth_qt, data = inc_fund_df)
trump_fund_pred <- as.data.frame(predict(inc_fund_model, corona_df,
                 interval = "prediction", 
                 level=0.95)) %>% 
  mutate(se = (upr - fit) / 1.96) %>%
  mutate(type = "Trump Fundamentals")
  
#model for biden with confidence intervals, fundamentals
chal_fund_model <- lm(formula = pv ~ gdp_growth_qt, data = chal_fund_df)
biden_fund_pred <- as.data.frame(predict(chal_fund_model,
                 corona_df,
                 interval = "prediction", 
                 level=0.95)) %>%
  mutate(se = (upr - fit) / 1.96) %>% 
  mutate(type = "Biden Fundamentals")

#created weights for trump's polls
weighted_trump_df <- polls_2020_df %>% 
  filter(stage == "general",
         candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  filter(is.na(state)) %>% 
  drop_na(fte_grade) %>% 
  filter(fte_grade != c("D", "F")) %>% 
  mutate(weight = case_when(fte_grade %in% c("A+", "A", "A-", "A/B") ~ 3,
                            fte_grade %in% c("B+", "B", "B-", "B/C") ~ 2,
                            fte_grade %in% c("C+", "C", "C-", "C/D") ~ 1)) %>% 
  mutate(end_date = mdy(end_date),
         election_date = mdy(election_date)) %>% 
  mutate(days_out = as.duration(interval(end_date, election_date)) / (60*60*24)) %>% 
  filter(days_out <= 59) %>% 
  filter(candidate_name == "Donald Trump")

#used survey package to assign weights
trump_poll_pred <- svydesign(id = ~1, weights = ~weight, data = weighted_trump_df)

#and used it again to get the estimates
trump_poll_pred <- svymean(~pct, trump_poll_pred)

#turned it into a tibble
trump_poll_pred <- tibble(fit = 41.999,
                          se = 0.1607) %>% 
  #link for equations https://www.healthknowledge.org.uk/e-learning/statistical-methods/practitioners/standard-error-confidence-intervals
  mutate(upr = (1.96 * se) + fit,
         lwr = fit - (1.96 * se)) %>%
  mutate(type = "Trump Poll")

#created weights for biden's polls
weighted_biden_df <- polls_2020_df %>% 
  filter(stage == "general",
         candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  filter(is.na(state)) %>% 
  drop_na(fte_grade) %>% 
  filter(fte_grade != c("D", "F")) %>% 
  mutate(weight = case_when(fte_grade %in% c("A+", "A", "A-", "A/B") ~ 3,
                            fte_grade %in% c("B+", "B", "B-", "B/C") ~ 2,
                            fte_grade %in% c("C+", "C", "C-", "C/D") ~ 1)) %>% 
  mutate(end_date = mdy(end_date),
         election_date = mdy(election_date)) %>% 
  mutate(days_out = as.duration(interval(end_date, election_date)) / (60*60*24)) %>% 
  filter(days_out <= 59) %>% 
  filter(candidate_name == "Joseph R. Biden Jr.")
  
#used survey package to assign weights
biden_poll_pred <- svydesign(id = ~1, weights = ~weight, data = weighted_biden_df)

#and used it again to get the estimates
biden_poll_pred <- svymean(~pct, biden_poll_pred)

#turned it into a tibble
biden_poll_pred <- tibble(fit = 50.717,
                          se = 0.1878) %>%
  #link for equations https://www.healthknowledge.org.uk/e-learning/statistical-methods/practitioners/standard-error-confidence-intervals
  mutate(upr = (1.96 * se) + fit,
         lwr = fit - (1.96 * se)) %>%
  mutate(type = "Biden Poll")

#http://mathbench.org.au/statistical-tests/testing-differences-with-the-t-test/6-combining-sds-for-fun-and-profit/ math for standard error combination
#.87 and .13 per poll weighting found here https://fivethirtyeight.com/features/how-fivethirtyeights-2020-presidential-forecast-works-and-whats-different-because-of-covid-19/
biden_comb_pred <- tibble(fit = ((.87 * biden_poll_pred$fit[1]) + (.13 * biden_fund_pred$fit[1])),
                          se = sqrt((.87 * biden_poll_pred$se[1])^2 + (.13 * biden_fund_pred$se[1])^2)) %>% 
  mutate(upr = (1.96 * se) + fit,
         lwr = fit - (1.96 * se)) %>%
  mutate(type = "Biden Ensemble")

#http://mathbench.org.au/statistical-tests/testing-differences-with-the-t-test/6-combining-sds-for-fun-and-profit/ math for standard error combination
trump_comb_pred <- tibble(fit = ((.87 * trump_poll_pred$fit[1]) + (.13 * trump_fund_pred$fit[1])),
                          se = sqrt((.87 * trump_poll_pred$se[1])^2 + (.13 * trump_fund_pred$se[1])^2)) %>% 
  mutate(upr = (1.96 * se) + fit,
         lwr = fit - (1.96 * se)) %>%
  mutate(type = "Trump Ensemble")

#combine all for one estimate table
estimate_df <- rbind(trump_fund_pred, biden_fund_pred, trump_poll_pred, biden_poll_pred, trump_comb_pred, biden_comb_pred)

#reordered columns using this link for reference http://www.sthda.com/english/wiki/reordering-data-frame-columns-in-r
estimate_df <- estimate_df[, c(5, 1, 2, 3, 4)] 

#made estimate gt table using this link for reference https://gt.rstudio.com/articles/intro-creating-gt-tables.html
estimate_table <- estimate_df %>% 
  gt() %>% 
  tab_header(
    title = "Percent of Populate Vote Estimates",
    subtitle = "2020 Presidential Election") %>% 
  cols_label(
    type ="Model Type",
    fit = "Point Estimate",
    lwr = "Lower Bound",
    upr = "Upper Bound",
    se = "Standard Error") %>% 
  tab_source_note(source_note = md("Showing 95% confidence intervals")) %>% 
  #formatted numbers using this link https://gt.rstudio.com/reference/fmt_number.html
  fmt_number(decimals = 2,
             columns = 2:5)