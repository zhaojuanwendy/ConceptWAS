library(icesTAF)
library("logistf")
library("dplyr")
library("tidyr")
library(parallel)

print("detect cores")
print(detectCores())
#encode demographic features into numeric data
encode_cov<-function(df, gender='gender', race='race'){
  # change gender and race to numeric
  df$gender <- ifelse(df$gender == "F", 1, 0) # female = 1, male = 0
  for (unique_value in unique(df$race)) { # race columns: race_B (black), race_W (white), and race_o (other)
    if (unique_value == "B" | unique_value == "W") {
      df[paste("race", unique_value, sep = "_")] <- ifelse(df$race == unique_value, 1, 0) 
    }
    else {
      df["race_o"] <- ifelse(df$race == unique_value, 1, 0) 	
    }
  }
  df <- subset(df, select = -c(race))
  
  return(df)
}

# #load cui table, patient-cuis

run_conceptWAS<-function(input_file, output_file, cui_dict_file, cores=1){
  print("loading data...")
  print(input_file)
  df <- read.csv(input_file, header = TRUE, row.names = 1)
  colnames(df) = gsub('X', 'c', colnames(df))
  cui_dict = read.csv(cui_dict_file, header = TRUE, row.names = 1)

  
  n_cov=4
  n_cuis = ncol(df)-4-1 #minus outcome column and covariates
  print(n_cuis)
  #cui columns
  cui_names<-names(df[0:n_cuis])
  
  df=encode_cov(df)
  covariates<-c('gender',  'age', 'race_B', 'race_W', 'race_o', 'ehr_duration')
  outcome<-c('label')
  # cui_names_for_test<-cui_names[0:5] #just for test
  #run conceptWAS
  source('./R/conceptWAS.R')
  source('./R/con_as_logistf.R')
  result = conceptWAS(cui_names, outcome=outcome, cui_table=df, covariates=covariates, cores=cores)
  rownames(result) = gsub('c', '', rownames(result))
  
  # merge the results
  if(!missing(cui_dict)){
    cui_dict 
    merged_result <- merge(cui_dict, result, by="row.names")
    final_summary <- merged_result %>% select(cui_key, cui_pn, sty, OR,lower_CI,upper_CI,p,n_cui_in_cases,n_cui_in_controls,n_cases,n_controls, n_total)
    colnames(final_summary) = c('dict_key', 'cui_name', 'sty', 'odds_ratio', 'lower_CI', 'upper_CI', 'p_value',
                                'n_cui_in_cases','n_cui_in_controls','n_cases','n_controls', 'n_total')
 
  }
  else{
    final_summary <- result %>% select(cui_key,OR,lower_CI,upper_CI,p,n_cui_in_cases,n_cui_in_controls,n_cases,n_controls, n_total)
    colnames(final_summary) = c('dict_key', 'odds_ratio', 'lower_CI', 'upper_CI', 'p_value',
                                'n_cui_in_cases','n_cui_in_controls','n_cases','n_controls', 'n_total')
  }
  
  final_summary <- final_summary[order(final_summary$p),] # order by ascending p
  write.csv(final_summary, output_file, row.names=FALSE)
  
}

# main 
# input file cui_table, person_id, cui_1, cui_2, cui_3...., covarates, label
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = './data/summarized/conceptWAS-logistf.csv'
  args[3] = './data/raw/cui_dict.csv'
}else if (length(args)==2){
  args[3]= './data/raw/cui_dict.csv'
}

# output_path = './data/summarized/temporal/'
# mkdir(output_path)

# for (nw in week_inv){
#   input_file = paste0("./data/processed/temporal/cui_table_with_demo_label_by_0527_to_week", nw, ".csv")
#   output_file= paste0(output_path, "conceptWAS-logistf-covid_vs_all-by_0527_to_week", nw, ".csv")
#   run_conceptWAS(input_file, output_file, cui_dict)
# }
input_file = args[1]
output_file = args[2]
cui_dict_path = args[3]
run_conceptWAS(input_file, output_file, cui_dict_path, cores=-1)

