# Topic modeling, LDA, on Mac Millers Lyrics
# Input:
# - df with all lyrics from genius
# # - 1 word per line
# - metadata:
#   - track_name
#   - album_name
#   - album_release_year
#   - part_type: which kind of part is it in the lyrics. I.e. Intro, chorus, part, outro, ...
#   - with_mac_miller: Is Mac Miller recognised as the artist for the specific word, or is it a feature guest?

# ------------------------------------------------------------------------------
# Load Data
library(here)
rm(list = ls())
set_here()
data_path <- here("output", "lyrics_per_word_with_metadata_clean.csv")

df <- read.csv(data_path)

# ------------------------------------------------------------------------------
# EDA
# - siehe Tableau Workbook

# ------------------------------------------------------------------------------
# LDA
# - Normalise: everything lowercase (already done)
# - Tokenise: 1 word per row (already done)
# - Remove Stop Words
# - POS tagging
# - Lemmatization
# - Kollokationserkennung: Mit PMI häufige Wortkombinationen herausfinden und daraus n-grams machen

# Remove Stop Words
library(tidytext)
library(tidyverse)

data(stop_words)
custom_stop_words <- read.csv("custom_stop_words.csv")
df_stop_words_removed <- df %>% 
  anti_join(stop_words, by = c("Lyrics" = "word")) %>% 
  anti_join(custom_stop_words, by = c("Lyrics" = "word"))


# ------------------------------------------------------------------------------
# Baseline LDA Analysis
# - just stop words removed
# - LDA on whole corpus
# - LDA on albums vs. not albums
# - lda over time
#   - per album
#   - define timeframes of several years
#   - sliding windows























