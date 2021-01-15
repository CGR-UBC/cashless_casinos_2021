import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import seaborn as sns
import os


def load_predicted_data(group1,group2,exp,robust=0):
    if robust==1:
        predicted=pd.read_csv('robust_matrix_predicted.csv')
    else:
        predicted=pd.read_csv('matrix_predicted.csv')
    
    
    ind_diffs=pd.read_csv('../../../../data_for_analysis/ind_diffs_'+exp+'.csv')
    group=ind_diffs.loc[:,['Participant ID',group1,group2]]
    group.rename(columns={'Participant ID':'Participant'},inplace=True)
    predicted.rename(columns={'Participant.f':'Participant'},inplace=True)
    group.set_index('Participant',inplace=True)
    predicted.set_index('Participant',inplace=True)
    correctp=pd.merge(group,predicted,how='right',on='Participant')
    correctp=correctp[((correctp.loc[:,group1]==1) & (correctp.loc[:,'group'] == group1))|
                        ((correctp.loc[:,group2]==1) & (correctp.loc[:,'group'] == group2))]
    correctp=correctp.replace('Credit','Voucher')
    correctp.loc[:,'group']=correctp.loc[:,'group']+(' predicted')

    return(correctp)  

def load_predicted_data_ind_diffs(robust=0):
    if robust==1:
        predicted=pd.read_csv('robust_matrix_predicted.csv')
    else:
        predicted=pd.read_csv('matrix_predicted.csv')
    predicted.rename(columns={'Participant.f':'Participant'},inplace=True)
    correctp=predicted
    return(correctp)  

def load_behav():
    data=pd.read_csv('data_with_diagnostics.csv')
    data_crop=data.loc[:,['Participant.f','group','Final.balance',
                'Trial.no',
                'Next.bet.binary','predicted','Result','logResult',
                'logLoss.streak','Trial.type.binary','ISIms','logISI','Loss.streak.outcome...zero','sqrtTrial.no']]
    data_crop=data_crop.replace('Credit','Voucher')
    data_crop.loc[:,'group']=data_crop.loc[:,'group']+(' data')
    data_crop.rename(columns={'Participant.f':'Participant'},inplace=True)
    return(data_crop)

# +
def plot_for_pop(exp,correctp,data_crop,IV,DV,bins,xticklabels,xlabel,ylabel,robust=0):
    """Draw actual data and model prediction
    correctp=predicted data
    data_crop=raw data
    IV = String - Column of data that is IV
    DV = String - Column of data that is DV
    bins = define bins you want for raw data plot - int array
    xticklabels = how you want to label bins - array
    xlabel/ylabel - strings - for plot axes
    """
    

        
    if not os.path.exists('plots'):
        os.makedirs('plots')
        
    if exp == 'POP1':
        logLossmedian=1.386294
        colors = ["orangered", "silver"]
    else:
        logLossmedian=1.098612
        colors = ["steelblue", "silver"]
        
    customPalette = sns.set_palette(sns.color_palette(colors))
    plt.rc('font', size=15)   
      
    if IV=='Final.balance':
        correctp.loc[correctp['logLoss.streak'] == 0]
    if IV=='logLoss.streak':
        correctp.loc[correctp['Final.balance'] == 0]
    if IV == 'logResult':
        correctp.loc[correctp['Final.balance'] == 0]

    # Predicted
    IV_p=correctp.groupby(['group',IV]).mean().loc[:,'predicted']
    IV_p=IV_p.unstack(level=0)
    IV_p=pd.DataFrame(IV_p)
    if exp == 'POP1':
        #IV_p.reset_index(inplace=True)
        IV_p=IV_p.loc[:,['Voucher predicted','Cash predicted']]
    print(IV_p)
    # Raw Data
    # Create arbitrary bins and check N in each
    data_crop.loc[:,'IV.binned']=pd.cut(data_crop.loc[:,IV], 
            bins=bins)
    IV_nbins=pd.cut(data_crop.loc[:,IV], 
            bins=bins).value_counts()
    IV_data=data_crop.groupby(['Participant','IV.binned','group']).mean().loc[:,DV]
    IV_data=pd.DataFrame(IV_data)

    IV_data =  IV_data.stack(level=0).reset_index(level=0) \
                                              .reset_index().drop('level_2',axis=1) \
                                              .rename(columns={0:'DV'})
    print(IV_nbins)
    IV_nbins.to_csv('plots/'+IV+'binN.csv',header=False )
    # Build figure
    fig, (ax1, ax2) = plt.subplots(1,2,figsize=(8,4),sharey=True)
    #boxplot ax1
    if exp=='POP1':
        sns.boxplot(y='DV', x='IV.binned',data=IV_data,hue='group',
                   ax=ax1,palette=customPalette,linewidth=1,fliersize=5, hue_order=['Voucher data','Cash data'])
    else:
        sns.boxplot(y='DV', x='IV.binned',data=IV_data,hue='group',
                    ax=ax1,palette=customPalette,linewidth=1,fliersize=5)
    if IV == 'Trial.type.binary':
        IV_p.plot.bar(ax=ax2)
        ax1.xaxis.set_ticklabels(['Win','Loss'])
        ax2.xaxis.set_ticklabels(['Win','Loss'],rotation=0)
    else:
        IV_p.plot(ax=ax2)
    ax1.set_ylabel(ylabel)
    ax2.set_ylabel(ylabel)
    ax1.set_xlabel(xlabel)
    ax2.set_xlabel(xlabel)
    fig.legend(title=None,loc=1,frameon=False)
    ax1.legend().set_visible(False)
    ax2.legend().set_visible(False)
    if DV == 'logISI':
        ax1.set_ylim(bottom=5,top=9.5)
    # Change yaxis labels for boxplot - use minor ticks to define edges and turn off major
    xbins=[]
    for i in np.arange(-0.5, 100,1):
        xbins.append(i)
        if len(xbins)==len(xticklabels):
            break
    if IV != 'Trial.type.binary':
        ax1.xaxis.set_ticks(xbins,minor=True)
        ax1.xaxis.set_ticklabels(xticklabels,minor=True)
        ax1.xaxis.set_ticks([])
        ax1.xaxis.set_tick_params(which='minor',length=4)
    sns.despine(top=True,right=True)
    plt.tight_layout()
    if robust==1:
        fig.savefig(fname='plots/robust_'+IV +'.png',format='png',transparent=True)
        fig.savefig(fname='plots/robust_'+IV + '.eps',format='eps',transparent=True)
    else:
        fig.savefig(fname='plots/'+IV +'.png',format='png',transparent=True)
        fig.savefig(fname='plots/'+IV + '.eps',format='eps',transparent=True)
        
        
         
# -
def plot_hist_for_pop(exp,data_crop,IV):
    """Draw actual data and transformed data histogrmas
    """
    if not os.path.exists('plots'):
        os.makedirs('plots')
    DVdata=data_crop.loc[:,IV]    
    if exp == 'POP1':
        colors = ["orangered", "silver"]
    else:
        colors = ["steelblue", "silver"]
    
    plt.figure()
    customPalette = sns.set_palette(sns.color_palette(colors))
    plt.rc('font', size=15)   

    
    sns.distplot(DVdata,kde=False)
    sns.despine(top=True,right=True)
    ax = plt.gca()
    if IV == 'Loss.streak.outcome...zero':
        ax.set_xlim(right=75)
    plt.tight_layout()
    plt.savefig(fname='plots/hist_'+IV + '.eps',format='eps',transparent=True)


# +
def plot_for_pop_ind_diffs(exp,correctp,ind_diffs,IV,DV,xlabel,ylabel,robust=0):
    if not os.path.exists('plots'):
        os.makedirs('plots')
    
    """Draw model prediction for ind diffs
    IV = String - Column of data that is IV
    DV = String - Column of data that is DV
    ind_diffs = series of binary ind difs to plot
    xticklabels = how you want to label bins - array
    xlabel/ylabel - strings - for plot axes
    """
    if exp == 'POP1':
        logLossmedian=1
        PGSImean=1
        STTWmean=13
        GEQ_Flowmean=1
    else:
        logLossmedian=1
        PGSImean=2
        STTWmean=14
        GEQ_Flowmean=2

    # remove centering
    if IV=='Final.balance':
        correctp.loc[:,'Final.balance']=correctp.loc[:,'Final.balance']+40
    if IV=='logLoss.streak':
        correctp.loc[:,'logLoss.streak']=correctp.loc[:,'logLoss.streak']+logLossmedian
    
    correctp.loc[:,'PGSI']=correctp.loc[:,'PGSI']+PGSImean
    correctp.loc[:,'GEQ_Flow']=correctp.loc[:,'GEQ_Flow']+GEQ_Flowmean
    if DV=='Next.bet.binary':
        correctp.loc[:,'ST.TW']=correctp.loc[:,'ST.TW']+STTWmean
    
    for binaryIV in ind_diffs:
        
        IV_p=correctp.groupby([binaryIV,IV]).mean().loc[:,'predicted']
        IV_p=IV_p.unstack(level=0)
    

        # Build figure
        fig=plt.figure()
        ax1=fig.add_subplot(111)
        if IV == 'Trial.type.binary':
            IV_p.plot.bar(ax=ax1)
            ax1.xaxis.set_ticklabels(['Win','Loss'],rotation=0)
        else:
            IV_p.plot(ax=ax1)
        ax1.set_ylabel(ylabel)
        ax1.set_xlabel(xlabel)
        if DV=='Next.bet.binary':
            ax1.set_ylim(bottom=0,top=1)
        else:
            ax1.set_ylim(bottom=6,top=9)
        sns.despine(top=True,right=True)
        plt.tight_layout()
        if robust==1:
            fig.savefig(fname=('plots/robust_'+binaryIV + '_' + IV + '.png'),format='png',transparent=True)
            fig.savefig(fname=('plots/robust_'+binaryIV + '_' + IV + '.eps'),format='eps',transparent=True) 
        else:
            fig.savefig(fname=('plots/'+binaryIV + '_' + IV + '.png'),format='png',transparent=True)
            fig.savefig(fname=('plots/'+binaryIV + '_' + IV + '.eps'),format='eps',transparent=True)             
        
        
def plot_for_pop_ind_diffs_group(exp,correctp,ind_diffs,IV,DV,xlabel,ylabel,robust,group1,group2):
    if not os.path.exists('plots'):
        os.makedirs('plots')
    
    """Draw model prediction for ind diffs
    IV = String - Column of data that is IV
    DV = String - Column of data that is DV
    ind_diffs = series of binary ind difs to plot
    xticklabels = how you want to label bins - array
    xlabel/ylabel - strings - for plot axes
    """
    if exp == 'POP1':
        logLossmedian=1
        PGSImean=1
        STTWmean=13
        GEQ_Flowmean=1
    else:
        logLossmedian=1
        PGSImean=2
        STTWmean=14
        GEQ_Flowmean=2

    # remove centering
    if IV=='Final.balance':
        correctp.loc[:,'Final.balance']=correctp.loc[:,'Final.balance']+40
    if IV=='logLoss.streak':
        correctp.loc[:,'logLoss.streak']=correctp.loc[:,'logLoss.streak']+logLossmedian
    
    correctp.loc[:,'PGSI']=correctp.loc[:,'PGSI']+PGSImean
    correctp.loc[:,'GEQ_Flow']=correctp.loc[:,'GEQ_Flow']+GEQ_Flowmean
    if DV=='Next.bet.binary':              
        correctp.loc[:,'ST.TW']=correctp.loc[:,'ST.TW']+STTWmean

    
    group1_data=correctp[correctp.loc[:,group1]==1]
    group2_data=correctp[correctp.loc[:,group2]==1]
    

    
    for binaryIV in ind_diffs:
        
        
        IV_p=group1_data.groupby([binaryIV,IV]).mean().loc[:,'predicted']
        IV_p=IV_p.unstack(level=0)
        keep=IV_p
        # Build figure
        fig=plt.figure()
        ax1=fig.add_subplot(111)
        if IV == 'Trial.type.binary':
            IV_p.plot.bar(ax=ax1)
            ax1.xaxis.set_ticklabels(['Win','Loss'],rotation=0)
        else:
            IV_p.plot(ax=ax1)
        ax1.set_ylabel(ylabel)
        ax1.set_xlabel(xlabel)
        if DV == 'Next.bet.binary':
            ax1.set_ylim(bottom=0,top=1)
        else:
            ax1.set_ylim(bottom=6,top=9)

        sns.despine(top=True,right=True)
        plt.tight_layout()
        if robust==1:
            fig.savefig(fname=('plots/robust_'+binaryIV + '_' + IV  + group1 + '.png'),format='png',transparent=True)
            fig.savefig(fname=('plots/robust_'+binaryIV + '_' + IV  + group1 + '.eps'),format='eps',transparent=True) 
        else:
            fig.savefig(fname=('plots/'+binaryIV + '_' + IV +  '_' + group1 + '.png'),format='png',transparent=True)
            fig.savefig(fname=('plots/'+binaryIV + '_' + IV + '_' + group1 + '.eps'),format='eps',transparent=True)
        
        IV_p=group2_data.groupby([binaryIV,IV]).mean().loc[:,'predicted']
        
        IV_p=IV_p.unstack(level=0)
    
        # Build figure
        fig=plt.figure()
        ax1=fig.add_subplot(111)
        if IV == 'Trial.type.binary':
            IV_p.plot.bar(ax=ax1)
            ax1.xaxis.set_ticklabels(['Win','Loss'],rotation=0)
        else:
            IV_p.plot(ax=ax1)
        ax1.set_ylabel(ylabel)
        ax1.set_xlabel(xlabel)
        if DV == 'Next.bet.binary':
            ax1.set_ylim(bottom=0,top=1)
        

        sns.despine(top=True,right=True)
        plt.tight_layout()
        if robust==1:
            fig.savefig(fname=('plots/robust_'+binaryIV + '_' + IV  + group2 + '.png'),format='png',transparent=True)
            fig.savefig(fname=('plots/robust_'+binaryIV + '_' + IV  + group2 + '.eps'),format='eps',transparent=True) 
        else:
            fig.savefig(fname=('plots/'+binaryIV + '_' + IV +  '_' + group2 + '.png'),format='png',transparent=True)
            fig.savefig(fname=('plots/'+binaryIV + '_' + IV + '_' + group2 + '.eps'),format='eps',transparent=True)
    return(keep)
