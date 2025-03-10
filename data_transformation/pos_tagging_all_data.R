# POS Tagging Mac Miller

# - group by track
# - 
  
# Load Data
library(rstudioapi)

# Get root directory and set as working directory
rm(list = ls())
script_dir <- dirname(getActiveDocumentContext()$path)
project_dir <- dirname(script_dir)
setwd(project_dir)
print(getwd())  # Check working directory

data_path <- file.path(project_dir, "output", "lyrics_per_word_with_metadata_clean.csv")

# Load initial data
df <- read.csv(data_path)

#------------------------------------------------------------
# Prep data 
# Group together per track, to give POS algo more context

df_grouped <- df %>% 
  group_by(URL) %>% 
  summarise(text = paste(Lyrics, collapse = " "))

#------------------------------------------------------------
# POS Tagging
library(udpipe)

# download model
ud_model <- udpipe_download_model(language = "english")

# Load model
ud_model <- udpipe_load_model(file = ud_model$file_model)

# POS tagging function for a complete text
pos_tagging <- function(text) {
  annotated <- udpipe_annotate(ud_model, x = text)
  df_pos <- as.data.frame(annotated)
  return(df_pos)
}

# POS-Tagging for every track
df_grouped$pos_results <- lapply(df_grouped$text, pos_tagging)

# Unnest df with pos tagging
library(tidyverse)

df_grouped_pos_flat <- unnest(df_grouped, cols = pos_results) %>% 
  select(
    URL,
    token,
    lemma,
    upos,
    xpos
  ) %>% 
  rename(Lyrics = token)

# Add metainformation from original df back to POS tagged df
# NOT DONEEE

df_result <- df_grouped_pos_flat %>% 
  inner_join(df, by = "URL")

write.csv(df_grouped_pos_flat, "output/lyrics_per_word_with_metadata_clean_lemma_pos_tagged.csv")









  