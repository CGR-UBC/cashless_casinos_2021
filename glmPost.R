# Added conditional statements for code specific to logistic regression
# Added marginal model plots and avplots

glmPost<-function(model4diagnostics,data4diagnostics,nullmodel){
   if (file.exists('diagnostics')){
    } else {
    dir.create('diagnostics')
    } 
  model4diagnostics.modelChi<-model4diagnostics$null.deviance-model4diagnostics$deviance
  model4diagnostics.chidf <- model4diagnostics$df.null - model4diagnostics$df.residual
  model4diagnostics.chisq.prob <- 1 -pchisq(model4diagnostics.modelChi,model4diagnostics.chidf)
  
  if(model4diagnostics$family$family=='binomial'){
          cat("Pseudo R^2 for logistic regression","\n") 
          modelN <-length(model4diagnostics$fitted.values)
          # Hosmer and Lemeshows R square
          R.hl<-model4diagnostics.modelChi/model4diagnostics$null.deviance
          cat("Hosmer and Lemeshow R^2    ", round(R.hl,3),"\n")
          # Cox and Snell R square
          R.cs <- 1- exp ((model4diagnostics$deviance-model4diagnostics$null.deviance)/modelN)
          cat("Cox and Snell R^2          ", round(R.cs,3),"\n")
          # Nagelkerke R square
          R.n <-R.cs/(1-(exp(-(model4diagnostics$null.deviance/modelN))))
          cat("Nagelkerke R^2             ", round(R.n,3),"\n\n")

          test<- pROC::roc(model4diagnostics$y,model4diagnostics$fitted)
          cat("C-statistic                ", pROC::auc(test),"\n\n")
      
  }
     
    
  cat("Comparing test model with null model (participant only)","\n") 
  modelChi<-nullmodel$deviance-model4diagnostics$deviance
  chidf <- nullmodel$df.residual -model4diagnostics$df.residual
  chisq.prob <- 1 -pchisq(modelChi,chidf)
  cat("Chi square                 ", modelChi,"\n")
  cat("Chi square df              ", chidf,"\n")
  cat("Chi square prob            ", chisq.prob ,"\n\n")

  modelforprint<-(summary(model4diagnostics)$coefficients)
  modelforprint<-data.frame(modelforprint)
  if(model4diagnostics$family$family=='binomial'){    
      oddsratios<-exp(model4diagnostics$coefficients)
      oddsratios.frame<-data.frame(oddsratios) 
      modelforprint$or<-oddsratios.frame$oddsratios
      orconfidenceintervals<-exp(confint(model4diagnostics)) 
      orconfidenceintervals.frame<-data.frame(orconfidenceintervals)
      modelforprint$lci<-orconfidenceintervals.frame$X2.5..
      modelforprint$uci<-orconfidenceintervals.frame$X97.5..
      }
  if(model4diagnostics$family$family!='binomial'){
      confidenceintervals<-confint(model4diagnostics)
      confidenceintervals.frame<-data.frame(confidenceintervals)
      modelforprint$lci<-confidenceintervals.frame$X2.5..
      modelforprint$uci<-confidenceintervals.frame$X97.5..
      }
         
  data4diagnostics$predicted<-fitted(model4diagnostics)
  data4diagnostics$standardised.residuals<-rstandard(model4diagnostics)
  data4diagnostics$studentised.residuals<-rstudent(model4diagnostics)
  #data4diagnostics$dfbeta<-dfbeta(model4diagnostics)
  data4diagnostics$dffit<-dffits(model4diagnostics)
  data4diagnostics$leverage<-hatvalues(model4diagnostics)
  data4diagnostics$cooks<-cooks.distance(model4diagnostics)

  data4diagnostics$large.residuals<-data4diagnostics$standardised.residuals >2 |         data4diagnostics$standardised.residuals < -2
  cat("Number of residuals over +2 or - 2             ", sum(data4diagnostics$large.residuals),"\n\n")
  cat("Percent of residuals over +2 or - 2            ", sum(data4diagnostics$large.residuals)/length(data4diagnostics),"\n\n")
  J<-(mean(data4diagnostics$leverage))*3

  data4diagnostics$large.leverage<-data4diagnostics$leverage >J
  cat("Number of leverages over threshold           ", sum(data4diagnostics$large.leverage),"\n\n")
  cat("Percent of leverages over threshold           ", sum(data4diagnostics$large.leverage)/length(data4diagnostics),"\n\n")

  modelVars <- all.vars(formula(model4diagnostics)[-2]) # gets the predictors from the model
  DV <-all.vars(formula(model4diagnostics))[1]
  string<-c(modelVars,DV,"leverage","standardised.residuals","dffit","cooks")  
  
  large_leverage<-data4diagnostics[data4diagnostics$large.leverage,string]
  large_residuals<-data4diagnostics[data4diagnostics$large.residuals,string]
  write.table(large_residuals,"diagnostics/large_residuals.csv",sep=",",row.names=FALSE)
  write.table(large_leverage,"diagnostics/large_leverage.csv",sep=",",row.names=FALSE)
  write.table(modelforprint,"model.csv",sep=",")

  return(as.data.frame(data4diagnostics))
}


# +
glmPostfigs<-function(model4diagnostics,data4diagnostics,ind_diffs){
  
    if (file.exists('diagnostics')){
    } else {
    dir.create('diagnostics')
    }
    
  modelVars <- all.vars(formula(model4diagnostics))[3:length(all.vars(formula(model4diagnostics)))]
  rows=length(modelVars)/2
  jpeg('diagnostics/QQplot_and_resdiuals.jpg',width = 800, height = 400, units = "px")
  par(mfrow=c(1,2)) 
  qqnorm(data4diagnostics$standardised.residuals, ylab="Standardized Residuals",  xlab="Normal Scores") 
  qqline(data4diagnostics$standardised.residuals)
  plot(data4diagnostics$standardised.residuals, ylab="Standardised residuals")
  dev.off()

  jpeg('diagnostics/influence_plots.jpg',width = 900, height = 300, units = "px")
  par(mfrow=c(1,3)) 
  plot(data4diagnostics$leverage, ylab="Leverage")
  plot(data4diagnostics$dffit, ylab="DFFIT")
  plot(data4diagnostics$cooks, ylab="Cooks")
  dev.off()
    
  if(model4diagnostics$family$family!='binomial'){
      jpeg('diagnostics/mmps.jpg',width = 800, height = 800, units = "px")
      # marginal model plots from car
      mmps(model4diagnostics)
      dev.off()
      }
  
  jpeg('diagnostics/fitted.jpg',width = 800, height = 400, units = "px")
  par(mfrow=c(1,2)) 
  plot(model4diagnostics$fitted.values,model4diagnostics$y,xlab="Fitted Values")
  abline(lsfit(model4diagnostics$fitted.values,model4diagnostics$y))
  plot(model4diagnostics$fitted.values,data4diagnostics$standardised.residuals , ylab="Standardized Residuals", xlab="Fitted Values")
  dev.off()
  jpeg('diagnostics/predictors_vs_resid.jpg',width = 800, height = 800, units = "px")
  par(mfrow=c(rows,2)) 
  for (i in modelVars) {
     plot(data4diagnostics[,i], data4diagnostics$standardised.residuals , ylab="Standardized Residuals", xlab=i)
  }
  dev.off()
  
  if (ind_diffs!=1){  

      jpeg('diagnostics/avplots.jpg',width = 800, height = 800, units = "px")
      par(mfrow=c(rows,2)) 
      for (var in modelVars){
          if(var !='group')
              avPlot(model4diagnostics,variable=var,ask=FALSE)
              }
      dev.off()
      }
  
 
  cat("Diagnostic images created. Not all useful for logistic models.

- QQ plot 
      - Are residuals normal? If yes, is diagonal
- Influence measures
      - Leverage = an extreme observed value - but does it exert undue inluence on model?\
      - DFFIT = number of standard deviations that the fitted value changes when the ith data point is omitted.
      -  Cooks = delete ith observation, how much to all the fitted values change?.
- Fitted plots 
      - Fitted vs actual - should form a diagonal line and dots should be scattered randomly about the line if not logistic
      - Fitted vs residuals: - Should be no pattern, and should be symmetrical
- Predictors against standardised residuals. Should be no pattern if not logistic.
- Added-variable plots:
      - partial relationship between the response and a regressor, adjusted for all the other regressors.
- Marginal model plots: 
      - the response across the levels of a factor where all other factors are set to their average value.
      - Shows fit using data, and prediction of model - should be close. 
      - Last plot shows you prediction and fit of entire model (all regressors)
        Different to AVplots which adjust for other regressors, MM plots just ignore them")
  
}
