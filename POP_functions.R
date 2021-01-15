load_data<-function(DV,model,exp){
    # DV = BET or ISI
    # model = all, win, or loss
    
    # Centering variable - median as no data is totally normal, and round to nearest whole number
    
    # Result - use log due to insane levels of skew. also fits with diminihsing marginal returns
    
    data=read.csv("../../../../data_for_analysis/all_participants_trial_data.csv")

    if(exp == 'POP1'){
        data$group<-data$Cash
        data$group<-ifelse(is.na(data$group)==TRUE,0,1)
        data<- within (data, {group<-factor(group,levels=1:0,labels = c("Cash","Credit"))})
    } else {
        data$group<-ifelse(data$Earned==0,1,0)        
        data<- within (data, {group<-factor(group,levels=1:0,labels = c("Windfall","Earned"))})
        data<- within (data, {Game_mode<-factor(Cash_mode,levels=1:0,labels = c("Cash_mode","Credit_mode"))})
    }
    
    data$group<-factor(data$group)
    data$Stopper.binary<-ifelse(data$Stopper=="Yes", 1, 0) 
    data<-subset(data,Bonus.spins=="No") # remove bonus spins as only 70 ish in total

    data<-subset(data,Next.bet.amount>0) # remove last trial which has no next bet
    data<-subset(data,Preceding.loss.streak.outcome...zero>=0) # remove first trial which has no previous trial

    data$Time<-data$Time.of.bet.relative.to.first.bet
    data$Participant.f <-factor(data$Participant)


    data$Trial.type<-factor(data$Outcome...bet+data$Outcome...zero)
    data$Preceding.trial.type<-factor(data$Preceding.outcome...bet+data$Preceding.outcome...zero)

    data$Trial.type.binary<-data$Outcome...zero
    data$Preceding.trial.type.binary<-factor(data$Preceding.outcome...zero)

    # create rolling average of last 9 nlines
    data$rolling_nlines<-ave(data$N.lines, data$Participant.f, 
                      FUN= function(x) runmean(x, 9, alg="R",endrule="mean" ) )

    data$Reference<-ifelse(data$Final.balance>3999,1,0)

    data$Minimax<-ifelse(data$N.lines==30 & data$Multiplier==1,1,0)

    data$Next.bet.binary<-ifelse(data$Next.bet.amount > data$Median.bet,1,0)

    data$Final.balance<-data$Final.balance/100
    data$Final.balance.zero.centred<-round(data$Final.balance-40,digits=2)

    data<-subset(data,Final.balance<101) # where above max possible winnings (p65 and 67) - outliers and not within winnable amount.

    data$Binary.bet.change<-ifelse(data$Bet.change!=0,1,0)                        
    
    data$ISIms=data$ISI*1000                         
    data$logISI<-log(data$ISIms)
    
    # if(exp=='POP2'){
    #     data<-subset(data, Participant!=) # not a regular player
    #     data<-subset(data, Participant!=) # recording error
    #     
    #     data<-subset(data, Participant!=) # NAVON 
    #     data<-subset(data, Participant!=) # NAVON 
    #     data<-subset(data, Participant!=) # NAVON 
    # }
    #                          
    data$Trial.no.centred<-data$Trial.no-(median(data$Trial.no))
    cat('Median trial n            ',(median(data$Trial.no)),"\n")                         
    data$sqrtTrial.no<-sqrt(data$Trial.no)        
    data$sqrtTrial.no.centred<-data$sqrtTrial.no-(median(data$sqrtTrial.no)) 
    cat('Median sqrt trial n       ',(median(data$sqrtTrial.no)),"\n")                                            
                        
    windata<-subset(data,Result>0)
    lossdata<-subset(data, Result==0) 
    alldata<-data
    
    Trial.no.mean<-mean(alldata$Trial.no)
    
                             
    if(model=='win'){
        modeldata<-windata    
        modeldata$Result.centred<-modeldata$Result-(median(modeldata$Result))
        cat('Median Result         ',(median(modeldata$Result)),"\n")  
        modeldata$logResult<-log(modeldata$Result)
        modeldata$logResult.centred<-modeldata$logResult-(median(modeldata$logResult))                    
        cat('Median log Result   ',(median(modeldata$logResult)),"\n")   
    } else if (model=='loss'){
        modeldata<-lossdata
        modeldata$logResult<-0
        modeldata$Loss.streak.centred<-modeldata$Loss.streak.outcome...zero-(median(modeldata$Loss.streak.outcome...zero))
        cat('Median loss streak         ',(median(modeldata$Loss.streak.outcome...zero)),"\n")  
        modeldata$logLoss.streak<-log(modeldata$Loss.streak.outcome...zero)
        modeldata$logLoss.streak.centred<-modeldata$logLoss.streak-(median(modeldata$logLoss.streak))                    
        cat('Median log loss streak     ',(median(modeldata$logLoss.streak)),"\n") 
    } else {
        modeldata<-alldata
        modeldata$logResult<-0
    }  
   # remove participants who only have one win trial (but aren't excluded by script below)                          
   if(exp=='POP2'& model == 'win'){
        #modeldata<-subset(modeldata,Participant!=)# only has one win trial (but
            #is a bet change trial so not auto excluded)
        }
   if(exp=='POP2'& DV == 'ISI' & model == 'win'){
         #modeldata<-subset(modeldata,Participant!=)# only has one win trial 
        }   
                             
    if(DV=='BET'){
        # remove participants who don't change bet
        Bet.changes<-subset(modeldata,Next.bet.binary!=0)
        modeldata<-modeldata[modeldata$Participant.f %in% unique(Bet.changes$Participant.f),]
        cat("\nN trials                            ",nrow(modeldata),"\n")
        cat("N bet change trials                 ",nrow(subset(modeldata,Bet.change!=0)),"\n")
        cat("Original N                          ",length(unique(data$Participant.f)),"\n")
        cat("Bet change N in model data          ",length(unique(modeldata$Participant.f)),"\n\n")    
        

        
    } else {
        cat("\nN trials (original)                 ",nrow(modeldata),"\n")
        removedTrials<-subset(modeldata,ISI>10)
        write.table(removedTrials,"removed_trials_10s_ISI.csv",sep=",")
        modeldata<-subset(modeldata,ISI<=10)
        cat("N removed trials (ISI>10)           ",nrow(removedTrials),"\n")
        cat("N included trials                   ",(nrow(modeldata)),"\n")

    }
  
    ntrials_per_p<- modeldata %>% group_by(Participant.f) %>% tally() %>%  ungroup() %>%
                             complete(Participant.f, fill = list(N = 0, freq = 0))     
    write.table(ntrials_per_p,"trials_per_p.csv",sep=",",row.names=FALSE)
                        
    cat("Median trial per p                  ",median(ntrials_per_p$n,na.rm = TRUE),"\n")                 
    cat("Min trial per p                     ",min(ntrials_per_p$n,na.rm = TRUE), "\n")
    cat("Max trial per p                     ",max(ntrials_per_p$n,na.rm = TRUE),"\n")                          
    
    unique_table<-modeldata %>% distinct(Participant, .keep_all = TRUE)
    cat('\n\nIncluded participants:\n',unique_table$Participant)
    n_per_gp<-unique_table %>% group_by(group) %>% tally()
    cat('\n\n')
    print(n_per_gp)  
    
    ind_diffs<-unique_table
    
    GEQ_Flow_median<-median(ind_diffs$GEQ_Flow)
    cat('\nMedian GEQ Flow:        ',GEQ_Flow_median)  
    cat('\nLow GEQ Flow N:         ',nrow(subset(ind_diffs,ind_diffs$GEQ_Flow<=GEQ_Flow_median)))
    cat('\nHigh GEQ Flow N:        ',nrow(subset(ind_diffs,ind_diffs$GEQ_Flow>GEQ_Flow_median)))
    
    PGSI_median<-median(ind_diffs$PGSI)
    cat('\n\nMedian PGSI:        ',PGSI_median)  
    cat('\nLow PGSI N:         ',nrow(subset(ind_diffs,ind_diffs$PGSI<=PGSI_median)))
    cat('\nHigh PGSI N:        ',nrow(subset(ind_diffs,ind_diffs$PGSI>PGSI_median)))
    
    ST.TW_median<-median(ind_diffs$ST.TW)
    cat('\n\nMedian ST.TW:        ',ST.TW_median)                         
    cat('\nLow ST.TW N:         ',nrow(subset(ind_diffs,ind_diffs$ ST.TW<= ST.TW_median)))
    cat('\nHigh ST.TW N:        ',nrow(subset(ind_diffs,ind_diffs$ ST.TW> ST.TW_median)))                         
    
    modeldata$PGSI.binary<-ifelse(modeldata$PGSI>PGSI_median,1,0)                           
    modeldata$GEQ_Flow.binary<-ifelse(modeldata$GEQ_Flow>GEQ_Flow_median,1,0)                                        
    modeldata$ST.TW.binary<-ifelse(modeldata$ST.TW>ST.TW_median,1,0)   
                             
    return(modeldata)
} 
subset_data_win<-function(modeldata){
    cat("N trials                     ",nrow(modeldata),"\n")
    cat("N final balance less than $5 trials (removed)   ",nrow(subset(modeldata,Final.balance<5)),"\n")
    cat("N result > 1000 (removed)                        ",nrow(subset(modeldata,Result>1000)),"\n")
    subsetdata<-subset(modeldata,Result<=1000&Final.balance>=5)
    cat("N bet change in all data               ",nrow(subset(modeldata,Bet.change!=0)),"\n")
    cat("N bet change in cropped data           ",nrow(subset(subsetdata,Bet.change!=0)),"\n\n")
    return(subsetdata)
}

subset_data_loss<-function(modeldata){
    cat("N trials                                           ",nrow(modeldata),"\n")
    cat("N final balance less than $5 trials (removed)     ",nrow(subset(modeldata,Final.balance<500)),"\n")
    cat("N loss streak >20 (removed)                        ",nrow(subset(modeldata,Loss.streak.centred>20)),"\n\n")
    subsetdata<-subset(modeldata,Loss.streak.outcome...zero<=20&Final.balance>=5)
    return(subsetdata)
}

subset_data_all<-function(modeldata){
    cat("N trials                                        ",nrow(modeldata),"\n")
    cat("N final balance less than $5 trials(removed)   ",nrow(subset(modeldata,Final.balance<5)),"\n\n")
    subsetdata<-subset(modeldata,Final.balance>=5)
    return(subsetdata)
}


# Summary function that allows selection of which coefficients to include 
# in the coefficient table
# https://stackoverflow.com/questions/35388010/hide-some-coefficients-in-regression-summary-while-still-returning-call-r-squar                             
# mod for glm by EHLO
mod.summary = function(x, rows, digits=3) {
  options(scipen=100)
  # Print a few summary elements that are common to both lm and plm model summary objects
  cat("Call\n")
  print(x$call)
  cat("\nDeviance Residuals:\n")
  if (x$df.residual > 5) {
        x$deviance.resid <- setNames(quantile(x$deviance.resid, 
            na.rm = TRUE), c("Min", "1Q", "Median", "3Q", "Max"))
    }
  xx <- zapsmall(x$deviance.resid, digits + 1L)
  print.default(xx, digits = digits, na.print = "", print.gap = 2L)
  cat("\n")
  print(coef(x)[rows,],digits = digits)
  cat("\n(Dispersion parameter for ", x$family$family, " family taken to be ", 
        format(x$dispersion), ")\n\n", apply(cbind(paste(format(c("Null", 
            "Residual"), justify = "right"), "deviance:"), format(unlist(x[c("null.deviance", 
            "deviance")]), digits = max(5L, digits + 1L)), " on", 
            format(unlist(x[c("df.null", "df.residual")])), " degrees of freedom\n"), 
            1L, paste, collapse = " "), sep = "")
    if (nzchar(mess <- naprint(x$na.action))) 
        cat("  (", mess, ")\n", sep = "")
    cat("AIC: ", format(x$aic, digits = max(4L, digits + 1L)), 
        "\n\n", "Number of Fisher Scoring iterations: ", x$iter, 
        "\n", sep = "")
    correl <- x$correlation
    if (!is.null(correl)) {
        p <- NCOL(correl)
        if (p > 1) {
            cat("\nCorrelation of Coefficients:\n")
            if (is.logical(symbolic.cor) && symbolic.cor) {
                print(symnum(correl, abbr.colnames = NULL))
            }
            else {
                correl <- format(round(correl, 2L), nsmall = 2L, 
                  digits = digits)
                correl[!lower.tri(correl)] <- ""
                print(correl[-1, -p, drop = FALSE], quote = FALSE)
            }
        }
    }
    cat("\n")
}

# remove participants from summary                            
print.mod.summary<-function(model,modeldata){
    mod.summary(summary(model),(length(unique(modeldata$Participant.f))+1):length(model$coefficients))
}     


# from broom package
tidy.glmrob <- function (x, conf.int = FALSE, conf.level = 0.95, ...) {
  ret <- coef(summary(x)) %>% 
    as_tibble(rownames = "term")
  names(ret) <- c("term", "estimate", "std.error", "statistic", "p.value")
  
  if (conf.int) {
    ci <- stats::confint.default(x, level = conf.level) %>%
      as_tibble()

    names(ci) <- c("conf.low", "conf.high")
    ret <- ret %>%
      cbind(ci)
  }
  for(i in 2:ncol(ret)){
    ret[,i]<-ifelse((ret[,i]<1),signif(ret[,i],4), round(ret[,i],2))                              
  }
  ret
}

# robust plots
# plot showing reduction in deviance in robust model
robust_diagnostics<-function(model,robustmodel){
    
    if (file.exists('diagnostics')){
    } else {
    dir.create('diagnostics')
    } 
    if (file.exists('diagnostics/robust')){
    } else {
    dir.create('diagnostics/robust')
    } 
    
    dev1<-abs(robustmodel$residuals)
    dev2<-abs(model$residuals)

    n <- length(dev1)
    ord1 <- order(dev1)
    sdev1 <- sort(dev1) 
    sdev2 <- sort(dev2) 
    
    jpeg('diagnostics/robust/robust_residuals.jpg',width = 1200, height = 500, units = "px",pointsize = 20)

    par(mfrow=c(1,3)) 
    plot(ppoints(n), sdev1, type="b",pch=1,xlab="quantiles", ylab= " residuals")
    lines(ppoints(n), sdev2, type="b",pch=2)
    xuu <- ppoints(n)[n]
    text(xuu - .03, max(sdev1) + .1, ord1[n])
    text(xuu, max(sdev2) + .3, ord1[n])
    legend(x="topleft",legend=c("Robust","Conventional"), pch=c(1,2))
    plot(sdev1,ylab= " Robust model residuals")
    plot(sdev2,ylab= " Conventional model residuals")
    dev.off()
    
    jpeg('diagnostics/robust/robust_qq.jpg',width = 1200, height = 500, units = "px",pointsize = 20)
    par(mfrow=c(1,2)) 

    qqnorm(robustmodel$residuals, ylab="Robust model Residuals",  xlab="Normal Scores") 
    qqline(robustmodel$residuals)
    qqnorm(model$residuals, ylab="Conventional model residuals",  xlab="Normal Scores") 
    qqline(model$residuals)
    dev.off()
    

    }


robmodel_weights<-function(data4diagnostics,model4diagnostics,DV){
    if (file.exists('diagnostics')){
    } else {
    dir.create('diagnostics')
    } 
    
    if (file.exists('diagnostics/robust')){
    } else {
    dir.create('diagnostics/robust')
    } 
    
    if (DV=='ISI'){data4diagnostics$rweights<-model4diagnostics$rweights
                   } else {data4diagnostics$rweights<-model4diagnostics$w.r
                          }
    
    jpeg('diagnostics/robust/weights_by_participant.jpg',width = 1200, height = 500, units = "px",pointsize = 20)
    par(mfrow=c(1,1)) 
    cat("Participant weights               ", plot(data4diagnostics$Participant,data4diagnostics$rweights),"\n\n")
    dev.off()
    
    data4diagnostics$rweights_binary<-cut(data4diagnostics$rweights, breaks = c(-Inf, 0.5, Inf), 
                        labels = c("< 0.75","> 0.75"))
    weights_binary_per_p<- data4diagnostics %>% group_by(Participant.f,rweights_binary) %>% tally() %>%  ungroup() %>%
                             complete(Participant.f,rweights_binary, fill = list(N = 0, freq = 0))
    weight_trials_per_p<- data4diagnostics %>% group_by(Participant.f) %>% tally() %>%  ungroup() %>%
                             complete(Participant.f, fill = list(N = 0, freq = 0))
    small_weights<-subset(weights_binary_per_p,rweights_binary=='< 0.75')
    large_weights<-subset(weights_binary_per_p,rweights_binary=='> 0.75')
    weight_trials_per_p$p_small<-small_weights$n/(small_weights$n+large_weights$n)
    write.table(weight_trials_per_p,"diagnostics/robust/weight_less_than_point75_trials__proportion_per_p.csv",sep=",",row.names=FALSE)

    
    if(DV=='BET'){
        weights_binary_per_p_by_BET<- data4diagnostics %>% group_by(Participant.f,rweights_binary,Next.bet.binary) %>% tally() %>%  ungroup() %>%
                             complete(Participant.f,rweights_binary,Next.bet.binary, fill = list(N = 0, freq = 0))
        write.table(weights_binary_per_p_by_BET,"diagnostics/robust/by_BET_weight_less_than_point75_trials__proportion_per_p.csv",sep=",",row.names=FALSE)
        next_bet_1<-subset(data4diagnostics,Next.bet.binary== 1)
        next_bet_0<-subset(data4diagnostics,Next.bet.binary == 0)
        cat("Percent weights small next BET 0            ", nrow(subset(next_bet_0,rweights_binary=='< 0.75'))/nrow(next_bet_0),"\n")
        cat("Percent weights small next BET 1            ", nrow(subset(next_bet_1,rweights_binary=='< 0.75'))/nrow(next_bet_1),"\n\n")

    }
    
    modelVars <- all.vars(formula(model4diagnostics))[3:length(all.vars(formula(model4diagnostics)))]
    rows=ceiling(length(modelVars)/2)
    
    data4diagnostics_small<-subset(data4diagnostics,rweights_binary=='< 0.75')
    data4diagnostics_large<-subset(data4diagnostics,rweights_binary=='> 0.75')
    jpeg('diagnostics/robust/robust_weights.jpg',width = 2400, height = 2400, units = "px")
    par(mfrow=c(rows,2)) 
    for (var in modelVars) {
       plot(data4diagnostics[,var], data4diagnostics$rweights , ylab="weights", xlab=var,col = rgb(red = 0, green = 0, blue = 0, alpha = 0.3))
       if (is.factor(data4diagnostics[,var])==FALSE){
           cat(var," weights small (median)            ", mean(data4diagnostics_small[,var]),"\n")
           cat(var," weights large (median)            ", mean(data4diagnostics_large[,var]),"\n")
           cat(var," weights correlation               ", cor(data4diagnostics[,var],data4diagnostics$rweights),"\n\n")
       }
    }
    dev.off()
    
    if (DV == "ISI"){
        cat(var," weights correlation               ", cor(data4diagnostics$logISI,data4diagnostics$rweights),"\n\n")
        jpeg('diagnostics/robust/DV_and_weights.jpg',width = 600, height = 600, units = "px")
        plot(data4diagnostics$logISI,data4diagnostics$rweights,col = rgb(red = 0, green = 0, blue = 0, alpha = 0.3))
        abline(lm(data4diagnostics$logISI~data4diagnostics$rweights), col="red") 
        dev.off()
        } 
    if (DV == "BET"){
        cat(DV," weights correlation               ", cor(data4diagnostics$Next.bet.binary,data4diagnostics$rweights),"\n\n")
        jpeg('diagnostics/robust/DV_and_weights.jpg',width = 600, height = 600, units = "px")
        plot(data4diagnostics$Next.bet.binary,data4diagnostics$rweights,col = rgb(red = 0, green = 0, blue = 0, alpha = 0.3))
        abline(lm(data4diagnostics$Next.bet.binary~data4diagnostics$rweights), col="red") 
        dev.off()
        }
        
    
     return(as.data.frame(data4diagnostics))
}


apa_table<-function(data, filename, column_header=FALSE, row_names=FALSE, pcol = FALSE, title=FALSE,
                    decplaces = 2, sigfigs = 2,sigfigs_p = 3){
  
  require(extofficer)
  
  if(!isFALSE(pcol)){ #if p col has been specified, format column(s)
    for(i in pcol){
      data[,i]<-signif(data[,i],3)
      data[,i]<-ifelse(data[,i]<0.001, "< .001",data[,i])
      data[,i]<-ifelse(data[,i]>=0.001 & data[,i]<0.01, "< .01",data[,i])
      data[,i]<-ifelse(data[,i]>=0.01 & data[,i]<0.05, "< .05",data[,i])
    }
  }
  
  # format numbers for output
  for(i in 1:ncol(data)){
    if(data.class(data[,i])=="numeric"){
      data[,i]<-ifelse((data[,i]<1),signif(data[,i],sigfigs), round(data[,i],decplaces))  #round
    }
  }  
  
  th<-create_header(data)
  th$colA = column_header #replace column headers with specified strings
  
  if(!isFALSE(row_names)){data[,1]=row_names}
  
  ft <- create_ft( data, th) # use extofficer to create APA flextable
  ft<- add_header_lines(ft, values = "")
  ft<- add_header_lines(ft, values = title)
  docx_file <- paste0(filename,".docx")
  
  
  save_as_docx(ft, path = docx_file) # use officer to write to word
}

rename_cols_for_tables<-function(data){
  for(i in 1:ncol(data)){
    if(colnames(data)[i]=="term"){
      colnames(data)[i]=" "
    }
    if(colnames(data)[i]=="estimate"){
      colnames(data)[i]="Beta"
    }
    if(colnames(data)[i]=="conf.low"){
      colnames(data)[i]="95% CI (lower)"
    }
    if(colnames(data)[i]=="conf.high"){
      colnames(data)[i]="95% CI (upper)"
    }
    if(colnames(data)[i]=="p.value"){
      colnames(data)[i]="p value"
    }
    if(colnames(data)[i]=="OR"){
      colnames(data)[i]="Odds ratio"
    }
    if(colnames(data)[i]=="OR.low"){
      colnames(data)[i]="95% CI (lower)"
    }
    if(colnames(data)[i]=="OR.high"){
      colnames(data)[i]="95% CI (upper)"
    }
  }
  return(data)
  
}

rename_rows_for_tables<-function(data){
  for(i in 1:nrow(data)){
    if(data[i,1]=="sqrtTrial.no"){
      data[i,1]="Sqrt trial number"
    }
    else if(data[i,1]=="Binary.bet.change"){
      data[i,1]="Bet change"
    }
    else if(data[i,1]=="Binary.bet.change"){
      data[i,1]="Bet change"
    }
    else if(data[i,1]=="logResult"){
      data[i,1]="log Result (cents)"
    }
    else if(data[i,1]=="logResult:groupCredit"){
      data[i,1]="log Result * group"
    }
    else if(data[i,1]=="logResult:groupCash"){
      data[i,1]="log Result * group"
    }
    else if(data[i,1]=="logResult:groupEarned"){
      data[i,1]="log Result * group"
    }
    else if(data[i,1]=="logResult:groupWindfall"){
      data[i,1]="log Result * group"
    }
    else if(data[i,1]=="Final.balance"){
      data[i,1]="Machine balance ($)"
    }
    else if(data[i,1]=="Final.balance:groupCredit"){
      data[i,1]="Machine balance ($) * group"
    }
    else if(data[i,1]=="Final.balance:groupCash"){
      data[i,1]="Machine balance ($) * group"
    }
    else if(data[i,1]=="Final.balance:groupEarned"){
      data[i,1]="Machine balance ($) * group"
    }
    else if(data[i,1]=="Final.balance:groupWindfall"){
      data[i,1]="Machine balance ($) * group"
    }
    else if(data[i,1]=="logLoss.streak"){
      data[i,1]="Log loss streak ($)"
    }
    else if(data[i,1]=="groupCredit:logLoss.streak"){
      data[i,1]="Log loss streak ($) * group"
    }
    else if(data[i,1]=="groupCash:logLoss.streak"){
      data[i,1]="Log loss streak * group"
    }
    else if(data[i,1]=="logLoss.streak:groupEarned"){
      data[i,1]="Log loss streak ($) * group"
    }
    else if(data[i,1]=="logLoss.streak:groupWindfall"){
      data[i,1]="Log loss streak ($) * group"
    }
    else if(data[i,1]=="group_revCash:logLoss.streak"){
      data[i,1]="Log loss streak ($) * group reversed"
    }
  }
  return(data)
}

  

  
 