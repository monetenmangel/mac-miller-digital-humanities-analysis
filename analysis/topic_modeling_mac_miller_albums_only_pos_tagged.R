# Topic modeling, LDA, on Mac Millers Lyrics
# Input:
# - df with all lyrics from genius
# - df is POS tagged + lemmas
# - 1 word per line
# - metadata:
#   - track_name
#   - album_name
#   - album_release_year
#   - part_type: which kind of part is it in the lyrics. I.e. Intro, chorus, part, outro, ...
#   - with_mac_miller: Is Mac Miller recognised as the artist for the specific word, or is it a feature guest?

# ------------------------------------------------------------------------------
# Load Data
library(rstudioapi)

# Get root directory and set as working directory
rm(list = ls())
script_dir <- dirname(getActiveDocumentContext()$path)
project_dir <- dirname(script_dir)
setwd(project_dir)
print(getwd())  # Check working directory

data_path <- file.path(project_dir, "output", "output/lyrics_per_word_with_metadata_clean_lemma_pos_tagged.csv")

# Load initial data
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
library(readr)

data(stop_words)
custom_stop_words <- read.csv("analysis/custom_stop_words.csv")
X20_most_commom_words <- read_csv("analysis/20_most_commom_words.csv")
df_stop_words_removed <- df %>% 
  anti_join(stop_words, by = c("Lyrics" = "word")) %>% 
  anti_join(custom_stop_words, by = c("Lyrics" = "word")) %>% 
  anti_join(X20_most_commom_words, by = c("Lyrics" = "Lyrics")) %>% 
  filter(album_name_short != "No Album") %>% 
  filter(with_mac_miller == "True")


# ------------------------------------------------------------------------------
# Baseline LDA Analysis
# - just stop words removed
# - LDA on whole corpus
# - LDA on albums vs. not albums
# - lda over time
#   - per album
#   - define timeframes of several years
#   - sliding windows
library(quanteda)
require(topicmodels)

df_grouped <- df_stop_words_removed %>% 
  group_by(URL) %>% 
  summarise(text = paste(Lyrics, collapse = " "),
            release_year = first(release_year),
            album_name_short = first(album_name_short))

# Create corpus
corpus <- corpus(df_grouped, text_field = "text")

# Create tokens + stemmeing (stopwords are already removed)
tokens <- tokens(corpus, remove_punct = T) # %>% 
# tokens_wordstem()

# Create DTM
DTM <- dfm(tokens)

# Optional: Remove rare words
# Words that appear in less than 3 documents are removed
# DTM <- dfm_trim(DTM, min_docfreq = 3)

# Show matrix dimensions
dim(DTM)

# LDA ----------

K <- 7
alpha <- 0.02

# compute LDA model, inference with n iterations of Gibbs sampling
topicModel <- LDA(DTM, K, method = "Gibbs", control = list(
  iter = 500,
  seed = 1, 
  verbose = 25, 
  alpha = alpha))

# have a look at the results
tmResult <- posterior(topicModel)

# format of the resulting object
attributes(tmResult)

ncol(DTM) # lengthOfVocab

beta <- tmResult$terms
dim(beta)

rowSums(beta) # rows in beta sum to 1
nrow(DTM) # size of collection

# for every document we have a probability distribution of
# its contained topics
theta <- tmResult$topics
dim(theta) # nDocs(DTM) distributions over K topics

rowSums(theta)[1:10] # rows in theta sum to 1

terms(topicModel, 10)

# Give topics pseudo names aka top 10 terms per topic
topKtermsPerTopic <- terms(topicModel, 10)
topicNames <- apply(topKtermsPerTopic, 2, paste, collapse = " ")


library(reshape2)
library(ggplot2)
library(pals)

# get mean topic proportions per decade
topic_proportion_per_album <- aggregate(theta,
                                        by = list(album_name_short = df_grouped$album_name_short),
                                        mean)
# Vergib den aggregierten Spalten die Pseudonamen der Topics
colnames(topic_proportion_per_album)[2:(K+1)] <- topicNames

# Reshape des Data Frames in ein langes Format
vizDataFrame <- melt(topic_proportion_per_album, id.vars = "album_name_short")

# Plot der durchschnittlichen Topic-Anteile pro release_year
ggplot(vizDataFrame, aes(x = as.factor(album_name_short), y = value, fill = variable)) +
  geom_bar(stat = "identity") +
  ylab("Proportion") +
  scale_fill_manual(values = paste0(alphabet(20), "FF"), name = "Topic") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# ----------------------
# Save results with metadata

# current timestamp
timestamp <- Sys.time()

# name and path of active script
script_path <- rstudioapi::getActiveDocumentContext()$path
script_name <- basename(script_path)

# create run id
run_id <- paste0(
  tools::file_path_sans_ext(script_name),  # script w/o ".R"
  "_K", K,
  "_alpha", alpha,
  "_", format(timestamp, "%Y%m%d_%H%M%S")
)

# Create Topics df

# Extract topics
topics_out <- terms(topicModel, 10)
topics_df <- as.data.frame(topics_out, stringsAsFactors = FALSE)
# topics_df <- cbind(Topic = colnames(topics_out), topics_df)

# add metadata to data frames
topics_df$K       <- K
topics_df$alpha   <- alpha
topics_df$run_id  <- run_id

vizDataFrame$K       <- K
vizDataFrame$alpha   <- alpha
vizDataFrame$run_id  <- run_id

# Pivot topics_df
# Pivot every column with "Topic " in its name
topics_long <- topics_df %>%
  pivot_longer(
    cols = starts_with("Topic "),   # alle Spalten, die "Topic " heißen
    names_to = "topic_label",       # z. B. "Topic 1", "Topic 2", ...
    values_to = "word"             # das sind die Top-Wörter
  )

# Save results
# Create if not exist, otherwise union data to existing data

append_to_csv <- function(df, csv_path) {
  if (file.exists(csv_path)) {
    # Datei existiert schon -> einlesen
    existing_df <- read_csv(csv_path, show_col_types = FALSE)
    # Zusammenführen
    combined_df <- bind_rows(existing_df, df)
    # Neue Tabelle überschreibt die alte
    write_csv(combined_df, csv_path)
    message("Daten an bestehende CSV angehängt: ", csv_path)
  } else {
    # CSV existiert noch nicht -> neu anlegen
    write_csv(df, csv_path)
    message("Neue CSV erstellt: ", csv_path)
  }
}


append_to_csv(topics_long, "analysis_results/topics_long.csv")
append_to_csv(vizDataFrame, "analysis_results/vizData_long.csv")









