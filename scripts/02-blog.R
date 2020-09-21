#needed libraries
library(tidyverse)
library(janitor)

#loading in csvs and cleaned names
econ_df <- read_csv("data/econ.csv") %>% 
  clean_names()
local_df <- read_csv("data/local.csv") %>% 
  clean_names()
popvote_df <- read_csv("data/popvote_1948-2016.csv") %>% 
  clean_names()
popvotestate_df <- read_csv("data/popvote_bystate_1948-2016.csv") %>% 
  clean_names()

#cleaning local_df
#used below to figure out what areas would technically be double counted for the vote
#unique(local_df$state_and_area) 
local_df <- local_df %>% 
  filter(!state_and_area %in% c("Los Angeles County", "New York city"))

loca
