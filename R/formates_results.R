# Title     : TODO
# Objective : TODO
# Created by: juan
# Created on: 9/25/20


library("tools")
library(DescTools)
setwd('/Users/juan/Documents/Vandy/covid19')

# covid19 positive vs negative test
preprocess<-function(my.data, append_extral_sympt = FALSE){
  
  p_cutoff=0.05/nrow(my.data)

  # choose the final signals (significant that survive the corrected p-value or symptom with odds>1 and p<0.05
  d = my.data[my.data[, 'p_value']<p_cutoff, ]
  print(nrow(d))
  
  if (append_extral_sympt){
    others = my.data[(my.data[, 'p_value']>=p_cutoff) & (my.data[, 'p_value']<0.05) & (my.data[, 'odds_ratio']>1) & (my.data[, 'sty']=='Sign or Symptom'), ]
    d <- bind_rows(d, others)
    print(nrow(d))
  }


  #calculate the prevlance
  d['preva_in_cases' ] <- d['n_cui_in_cases']/d['n_cases']
  d['preva_in_controls' ] <- d['n_cui_in_controls']/d['n_controls']
  d$preva_in_case = sprintf("%.1f%%", 100*d$preva_in_case)
  d$preva_in_controls = sprintf("%.1f%%", 100*d$preva_in_controls)
  
  d['case_cnt'] = paste0(d$n_cui_in_cases, ' (', d$preva_in_case,')')
  d['control_cnt'] = paste0(d$n_cui_in_controls, ' (', d$preva_in_controls,')')
  
  d$cui_name = StrCap(tolower(d$cui_name))
  d$odds_ratio<-sprintf("%.2f", d$odds_ratio)
  d$lower_CI<-sprintf("%.2f", d$lower_CI)
  d$upper_CI<-sprintf("%.2f", d$upper_CI)
  d$or_ci<-paste0(d$odds_ratio, ' (', d$lower_CI, ',', d$upper_CI, ')')
  
  top_signals = row.names(d)
  for (s in top_signals){
    sp = str_split(s, "_", simplify = TRUE)
    attr = sp[2]
    # find negated and add negated to the signal
    if (attr == 'neg'){
      d[s, ]$cui_name = paste0(d[s, ]$cui_name, '(negated)')
    }
    if (!is.na(d['c586120_pos', ]$cui_name) ){
      d['c586120_pos', ]$cui_name = "Smoking Monitoring Status"
    }
   
  }
  
  tabletext <- d[, c('cui_name' , 'sty', 'case_cnt', 'control_cnt',  'or_ci', 'p_value')]
  colnames(tabletext) <- c("Concept Name", "Semantic type", "Case Count (%)", "Control Count(%)", "OR (95%CI)", "P-value")
  return (tabletext)
  
}

df <-
  read.csv(
    "./data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_to_week12.csv",
    header = TRUE,
    row.names = 1, stringsAsFactors = FALSE,
  )

preprocessed_sigs = preprocess(df)
head(preprocessed_sigs)
# write.csv(preprocessed_sigs, './data/summarized/conceptWAS-logistf-covid_vs_all-by_0527_to_week12_sigs_0924_with_more_symp_for_publish.csv', row.names=TRUE)


for (nw in c(10, 8 , 6, 4, 2)) {
  input_file = paste0(
    "./data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_to_week",
    nw,
    ".csv"
  )
  df <- read.csv(input_file, header = TRUE, row.names = 1, stringsAsFactors = FALSE)
  preprocessed_sigs = preprocess(df, append_extral_sympt=FALSE)
  output_file = paste0(
    "./data/summarized/publish_for_nature/conceptWAS-logistf-covid_vs_all-by_0527_to_week",
    nw,
    "_sigs.csv"
  )
  write.csv(preprocessed_sigs, output_file, row.names=TRUE)
  
}

