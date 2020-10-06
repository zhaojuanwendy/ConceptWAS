library(ggplot2)
# library(ggrepel)
# devtools::install_github('kevinblighe/EnhancedVolcano')
library(EnhancedVolcano)
library("tools")
library(gridExtra)
library(grid)


# covid19 positive vs negative test


# start of the program, read the data for the week12
df <-
  read.csv(
    "./data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_to_week12.csv",
    header = TRUE,
    row.names = 1, stringsAsFactors = FALSE,
  )

df <- df[, c("cui_name", "odds_ratio", "p_value", "sty")]

# 1202 concepts with p < 0.05, 68 concepts with p < 0.05 / number of concepts (19595)
# log2 of odds ratio
df[, "odds_ratio"] <- log2(df[, "odds_ratio"])
df$cui_name = toTitleCase(tolower(df$cui_name))
#select top signals that need to label
top_signals = c(
  'c11570_pos',
  'c13604_pos',
  'c15967_neg',
  'c3467_pos',
  'c3126_pos',
  'c1880200_pos',
  'c586120_pos',
  'c15967_pos',
  'c1277295_pos',
  'c43144_pos',
  'c337671_pos',
  'c2364111_pos',
  'c36572_pos'
)

df['c586120_pos', ]$cui_name = "Smoking Monitoring Status"

library(tidyverse)
for (s in top_signals){
  sp = str_split(s, "_", simplify = TRUE)
  attr = sp[2]
  # find pos and add their negated to the opposite key
  if (attr == 'pos'){
    neg_cui_key = paste0(sp[1], "_neg")
    print(neg_cui_key)
    # if exist the negated cui, append the (neg) after the cui name
    if (!is.na(df[neg_cui_key, ]$cui_name)) {
      df[neg_cui_key, ]$cui_name = paste0(df[neg_cui_key, ]$cui_name, '(neg)')
    }
  }
 
}

# color by semantic type
keyvals <- ifelse(
  df$sty == "Finding" & df$p_value < 0.05,
  'red',
  #ifelse(df$sty == "Geographic Area" & df$p_value < 0.05, 'gold',
  ifelse(
    df$sty == "Mental or Behavioral Dysfunction" &
      df$p_value < 0.05,
    'blue',
    ifelse(
      df$sty == "Sign or Symptom" & df$p_value < 0.05,
      'purple1',
      ifelse(
        df$sty == "Laboratory or Test Result" &
          df$p_value < 0.05,
        'green',
        'black'
      )
    )
  )
)

names(keyvals)[keyvals == 'black'] <- 'Other'
names(keyvals)[keyvals == 'red'] <- 'Finding'
#names(keyvals)[keyvals == 'gold'] <- 'Geographic Area'
names(keyvals)[keyvals == 'blue'] <-
  'Mental or Behavioral Dysfunction'
names(keyvals)[keyvals == 'purple1'] <- 'Sign or Symptom'
names(keyvals)[keyvals == 'green'] <- 'Laboratory or Test Result'

p_cutoff=0.05/nrow(df)
p1 <-
  EnhancedVolcano(
    df,
    lab = df$cui_name,
    x = "odds_ratio",
    y = "p_value",
    ylim = c(0, 16),
    selectLab = df[top_signals, ]$cui_name,
    pCutoff = p_cutoff,
    colCustom = keyvals, # color by semantic type
    title = '',
    subtitle = '',
    caption = '',
    drawConnectors = TRUE,
    widthConnectors = 0.5,
    colConnectors = 'grey50',
    gridlines.minor = FALSE,
    gridlines.major = FALSE,
    legendLabSize = 14
  ) + guides(fill=guide_legend(nrow=2,byrow=TRUE))

p1
