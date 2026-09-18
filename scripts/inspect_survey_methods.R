suppressPackageStartupMessages(library(survey))
cat('svypredmeans:\n');print(svypredmeans)
cat('svyglm influence implementation:\n'); x<-deparse(survey:::svyglm.survey.design);cat(x[grep('infl|rescale|cov.unscaled|estfun|svy.varcoef',x)],sep='\n')
