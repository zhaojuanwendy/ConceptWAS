# Title     : TODO
# Objective : TODO
# Created by: juan
# Created on: 9/22/20
library(DT)
library(dplyr)
library(tools)
library("rstudioapi")
setwd(dirname(getActiveDocumentContext()$path))
setwd('../../')

my.right_join <- function(x, y, by = NULL) {
  merged = merge(x, y, by = by, all.y = TRUE)
  return(merged)
}


# preprocess the data
preprocess <- function(output_file) {
  nw = 12
  df_final <-
    read.csv(
      './data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_to_week12.csv',
      header = TRUE
    )

  # find target interested CUIs that want to show on the plot (from the final week)
  cui_list = c(
    'c11570_pos',
    'c13604_pos',
    'c15967_neg',
    'c3467_pos',
    'c586120_pos',
    'c3126_pos',
    'c1880200_pos',
    'c15967_pos',
    'c1277295_pos',
    'c43144_pos',
    'c337671_pos',
    'c2364111_pos',
    'c36572_pos'
  )
  length(cui_list)
  
  sigs_final = subset(df_final, df_final$dict_key %in% cui_list)[c('dict_key', 'p_value')]
  sigs_final = rename(sigs_final, c("p_value_nw_12" = "p_value"))
  
  # get the p-values from the previsou week data for the target cuis
  results = data.frame(week = 12, p = 0.05 / nrow(df_final), n_cases = df_final$n_cases[1])

  for (nw in c(10, 8 , 6, 4, 2)) {
    input_file = paste0(
      "./data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_to_week",
      nw,
      ".csv"
    )
    # print(input_file)
    # subs = get_cuis_p(input_file, cui_list)
    df <- read.csv(input_file, header = TRUE)
    
    #how many cross the bonferroni and save the p-values
    sig_level = 0.05 / nrow(df)
    
    df['cross_buff'] = ifelse(df['p_value'] < sig_level, 1, 0)
    print("cross bonferroni")
    print(sum(df['cross_buff']))
    # keep the current p-value levels
    results <- bind_rows(results, data.frame(week = nw, p = sig_level, n_cases = df$n_cases[1]))
    # store the current case number
    
    selected_cuis = subset(df, df$dict_key %in% cui_list)[c('dict_key', 'p_value')]
    selected_cuis =  rename_with(selected_cuis, function(x)
      paste0(x, "_nw_", nw), starts_with("p_value"))
    
    #store the select cuis and their p-values
    sigs_final <-
      my.right_join(selected_cuis, sigs_final, by = "dict_key")
    
  }

  final_summary <-
    merge(df_final[c('dict_key', 'cui_name')], sigs_final, by = 'dict_key')
  final_summary <-
    final_summary[order(final_summary$p_value_nw_12), ]
  
  results <- results[order(results$week),]
  return(results) 
}

output_file = './data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_sigs_all_weeks.csv'
results = preprocess(output_file) #

df = read.csv(output_file, header = TRUE, row.names = 1)

#reformat the columns names and add attributes of neg for negated attributes
df$cui_name = toTitleCase(tolower(df$cui_name))
df['c15967_neg', ]$cui_name = paste0(df['c15967_neg', ]$cui_name, '(negated)')
df['c586120_pos', ]$cui_name = "Smoking Monitoring Status"

tr = data.frame(t(df[-1]))
colnames(tr) = df[, 1]

wlist = c("2", "4", "6", "8", "10", "12") #weeks list
tr['idx'] <- wlist #use as index

library(reshape2)
#reshape the data for plot
d =  melt(tr, id.vars = "idx")
d$value = (-1) * log10(d$value)  # change p-value level to -log(10)
d[is.na(d)] = 0 #fill na

results$p_log = (-1) * log10(results$p)
results$n_cases_log = log10(results$n_cases)
#n
library(ggplot2)


suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(gridExtra))
#c("2 (by Mar 22)", "4 (by April 5)", "6 (by April 19)", "8 (by May 3)", "10 (by May 17)", "12 (by May 27)")
source('~/ggplot_theme_Publication-2.R')
g <-
  ggplot(d, aes(idx, value, colour = factor(variable), group = variable)) +
  geom_line(size=0.8) +
  geom_point(aes(shape = factor(variable)), size=3) + scale_shape_manual(values=c(16, 1, 15, 3, 17, 18, 19, 5, 20, 8, 24, 23, 4))+
  scale_x_discrete(limit = wlist, labels= c("2", "4", "6", "8", "10", "12")) +
  geom_line(
    data = results,
    aes(x = factor(week), y = p_log, group = 1),
    color = 'black',
    linetype = "dashed"
  ) +
  # geom_line(data = results, aes(x = factor(week), y = n_cases),color = 'green',linetype = "dashed") +
  xlab("Weeks") + theme_Publication(base_family="Helvetica") + ylab("-Log10(p-value)") + 
  theme(legend.title = element_blank(), legend.text = element_text(size = 14), 
        legend.position = 'right', legend.spacing = unit(1, "cm"))

g

ggsave(
  './images/temporal_0923.eps',
  device = 'eps',
  dpi = 150,
  width = 9,
  height = 6
)


g2 <-
  ggplot( data = results,
          aes(x = factor(week), y = n_cases, group=1)) +
  geom_point(size=2)+
  scale_x_discrete(limit = wlist,  labels=c("2", "4", "6", "8", "10", "12")) +
  geom_line(
    color = 'black'
  ) +
  ylab("Number of COVID+") + xlab("Weeks") + theme_Publication(base_family="Helvetica") +    
  
  theme(legend.title = element_blank(), legend.text = element_text(size = 12), 
        legend.position = 'right', legend.spacing = unit(1, "cm"))

g2
ggsave(
  './images/temporal_cases_0930.eps',
  device = 'eps',
  dpi = 150,
  width = 5,
  height = 3
)
