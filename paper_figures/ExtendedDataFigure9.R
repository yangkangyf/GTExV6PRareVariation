# =======================================================================================================
# This is a script for generating "Extended Data Figure 9": Enrichment of genomic features used for RIVER
#
# input:
#       1. RIVER.out.RData
#          Data generated by running main_RIVER.R
#       2. enrichment.sorted.subset.txt: enrichment of genomic features via univariate logistic regression
#          [# of genomic features used for RIVER x (feature names, feature labels, categories, Log Odds Ratio, 
#          -95 % confidence interval, + 95 % confidence interval, -log10(P-value), significance)]
#
# output:
#       1. ExtendedDataFigure9.i.pdf (i = 1, 2, 3, 4, 20 features per figure)
#       2. ExtendedDataFgiure9.out.RData
#          Store all data used and generated by running this script
#
# Note that the final figure was generated by using inkscape by combining figures from this script for visualization purposes
#
# =======================================================================================================

#!/usr/bin/env Rscript

# Recall required packages
rm(list=ls(all=TRUE))

# Master directory
dir = Sys.getenv('RAREVARDIR')

# Recall required functions
source("getPlots.R") # this code should be in the same directory as the directory for this script



# =========== Load input data
load(file = paste(dir,"/data/RIVER.out.RData",sep=""))



# =========== Main
# Enrichment analysis of genomic features with univariate logistic regression model
enr_result = data.frame(matrix(NA,ncol(g_all),8))
colnames(enr_result) = c("features","labels","groups","lor","lowCI","highCI","nlog10pval","significance")
enr_result[,"features"] = colnames(g_all)

for (i in 1:ncol(g_all)) {
  # enr_result[i,"features"] = colnames(G)[i] 
  features <- data.frame(y=E_disc, x = g_all[,i])
  model <- glm(y ~ x, data = features, family = "binomial")
  temp_int = confint(model)[2,]
  enr_result[i,4:ncol(enr_result)] = cbind(summary(model)$coefficients[2],
                               ifelse(is.na(temp_int[1])==TRUE,summary(model)$coefficients[2]-abs(summary(model)$coefficients[2]-temp_int[2]),temp_int[1]),
                               temp_int[2], -log10(summary(model)$coefficients[2,"Pr(>|z|)"]),
                               ifelse(-log10(summary(model)$coefficients[2,"Pr(>|z|)"])+log10(0.05) > 0,1,0))
  # Report results
  print(paste("*** [",i,"] features: ",enr_result[i,"features"]," ***",sep=""),quote=FALSE)
  print(paste("    >> LOR = ",round(enr_result[i,4],3),", -CI = ",round(enr_result[i,5],3),", +CI = ",round(enr_result[i,6],3),sep=""),quote=FALSE)
}
enr_result_sorted = enr_result[order(enr_result[,"lor"],decreasing=TRUE),]
write.table(enr_result_sorted, file = paste(dir,"/data/enrichment.sorted.txt",sep=""),
            quote=FALSE, sep="\t", row.names=FALSE, na="NaN");



# =========== Load input data
# Most significant feature was selected for visualization if there is more than one feature from same genomic annotations (manual curation)
enr_features = read.table(paste(dir,"/data/enrichment.sorted.subset.txt",sep=""), 
                          sep='\t', header = TRUE, na.strings = "NaN"); 

# Add gray color for insignificant features
enr_features = data.frame(enr_features,colors=matrix(NA,nrow(enr_features),1)) 

for (i in 1:nrow(enr_features)) {
  enr_features[i,"colors"] = ifelse(enr_features[i,"significance"]==1,as.character(enr_features[i,"groups"]),"NE")
}
list_groups = as.character(unique(enr_features[,"groups"]))
data_sorted = enr_features[order(enr_features[,"groups"],enr_features[,"lor"],decreasing=FALSE),]

# Allocate colors for different categories of genomic annotations
cbPalette <- c(CONSERVATION="firebrick",DNASUMMARY="darkorange2",VEP="goldenrod2",ENCODE="deeppink1",
               HMM="dodgerblue",SEGWAY="darkorchid2",ROADMAP="forestgreen","NE"="gray")

nsample = 20
for (i in 1:4) {
  if (i < 4){
    data_sorted1 = data_sorted[(1+nsample*(i-1)):(nsample*i),]
  } else if (i == 4) {
    data_sorted1 = data_sorted[(1+nsample*(i-1)):nrow(enr_features),]
  }
  
  data <- data.frame(x=data_sorted1[,"lor"],y=seq(1,nrow(data_sorted1),1),
                     xlow=data_sorted1[,"lowCI"],xup=data_sorted1[,"highCI"],
                     cond=data_sorted1[,"groups"],labels=data_sorted1[,"labels"],
                     col=data_sorted1[,"colors"])
  data$x = as.numeric(as.character(data$x))
  data$xup = as.numeric(as.character(data$xup))
  data$xlow = as.numeric(as.character(data$xlow))
  data$y = as.factor(data$y)
  Annotation = as.character(data$col)
  
  getForestPlots(data, Annotation) # points with errorbars
  
  ggsave(paste(dir,"/paper_figures/ExtendedDataFigure9.",i,".pdf",sep=""), width = 8, height = 4) 
}



# =========== Save data
save.image(file = paste(dir,"/data/ExtendedDataFigure9.out.RData",sep=""))