con_as_logistf<-function(cui.paras, my.data, covs){
  # print(which(cui_names == cui))
  # ignore cuis that no patients have
  
  if(!missing(my.data)) data=my.data
  #Retrieve the targets for this loop
  cui=cui.paras[[1]]
  outcome=cui.paras[[2]]
  
  #Subset the data
  df=data %>% select(one_of(na.omit(unlist(c(cui,outcome,covs)))))
  
  if (sum(df[[cui]]) != 0) { 
    n_total = nrow(df)
    
    n_cases<-sum(df[[outcome]])
    n_controls <- n_total-n_cases
    
    # number of case with cui 
    n_cui_in_cases = nrow(df[df[outcome]==1 & df[cui]==1, ])
    # number of controls with cui 
    n_cui_in_controls = nrow(df[df[outcome]==0 & df[cui]==1, ])
    
    #Create the formula:
    formula.string = paste0("`", outcome,"` ~ `",paste(na.omit(c(cui, covs)), collapse = "` + `"),'`')
    my.formula = as.formula(formula.string)
    # print(my.formula)
    
    # firth logistic regression with cui as predictor and gender, age, and race as covariates 
    fit = logistf::logistf(my.formula, data=df, dataout=F)
    
    
    #Find the rows with results, odds ratio, 95% CI, and p value
    or <- exp(fit$coefficients[cui])
    beta <- fit$coefficients[cui]
    p <- fit$prob[cui]
    lower_CI <- exp(fit$ci.lower[cui])
    upper_CI <- exp(fit$ci.upper[cui])
    
    output=data.frame(cui_key=cui,
                      beta=beta, 
                      OR=or,
                      p=p, 
                      lower_CI=lower_CI,
                      upper_CI=upper_CI,
                      n_cui_in_cases=n_cui_in_cases, n_cui_in_controls=n_cui_in_controls,
                      n_cases=n_cases, n_controls=n_controls,
                      n_total=n_total,
                      formula=formula.string)
    
   return(output)
    
  }
}