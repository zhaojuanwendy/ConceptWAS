# Title     : ConceptWAS
# Objective : conceptWAS
# Created by: juan
# Created on: 9/20/20
conceptWAS<-function(cui_names, outcome, cui_table, covariates=c(NA), cores=1, adjustments=list(NA), method='logistf', unadjusted=F){
  
  if(unadjusted) {
    if(!is.na(covariates) | !is.na(adjustments)) warning("Covariates and adjustments are ignored in unadjusted mode.")
  }
  if (method == 'logistf'){
    association_method=con_as_logistf
  }
  df = cui_table
  para=(cores>1 | cores<=-1)
  
  #Create the list of combinations to iterate over
  full_list=data.frame(t(expand.grid(cui_names, outcome, stringsAsFactors=F)), stringsAsFactors=F)
  
  #If parallel, run the parallel version.
  if(para) {
    #Check to make sure there is no existing conceptWAS cluster.
    # if(exists("conceptWAS.cluster.handle")) {
    #   #If there is, kill it and remove it
    #   try(stopCluster(conceptWAS.cluster.handle), silent=T)
    #   rm(phewas.cluster.handle, envir=.GlobalEnv)
    # }
    print("running parallel...")
    # assign("conceptWAS.cluster.handle", makeCluster(cores), envir = .GlobalEnv)
    # print("Cluster created, finding associations...")
    # clusterExport(conceptWAS.cluster.handle,c("df", "covariates"), envir=environment())
    #Loop across every concept(cui)- iterate in parallel
    # if cores ==-1 use all cores
    if (cores==-1) {
      print("use all cores...")
      print(system.time(result <-mclapply(full_list, association_method,df, covariates )))
    }
    else {
      print(system.time(result <-mclapply(full_list, association_method,df, covariates, mc.cores = cores )))
    }
    #Once we have succeeded, stop the cluster and remove it.
    # stopCluster(conceptWAS.cluster.handle)
    # rm(conceptWAS.cluster.handle, envir=.GlobalEnv)
    
  }
  else{
    #Otherwise, just use lapply.
    print("Finding associations...")
    print(system.time(result<-lapply(full_list, FUN=association_method, df, covariates)))
  }
  sumry = bind_rbind_rowsows(result)
  return(sumry)
}
