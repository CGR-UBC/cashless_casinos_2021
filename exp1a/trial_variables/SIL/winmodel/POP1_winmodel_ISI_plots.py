# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: light
#       format_version: '1.4'
#       jupytext_version: 1.2.4
#   kernelspec:
#     display_name: Python 3
#     language: python
#     name: python3
# ---

# +
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import seaborn as sns

import sys
sys.path.append('../../../../../')


from POP_functions import *
# -

group1=('Cash')
group2=('Credit')
correctp=load_predicted_data(group1,group2,'POP1')
data_crop=load_behav()
robust_correctp=load_predicted_data(group1,group2,'POP1',1)

# ## logResult plots


plot_for_pop('POP1',correctp,data_crop,
                 'logResult','logISI', 
                 [0,3,4,5,6,np.inf],
                 ['','<3','4','5','>6'], 'log(Win size)','log(Spin initiation latency)')

plot_for_pop('POP1',robust_correctp,data_crop,
                 'logResult','logISI', 
                 [0,3,4,5,6,np.inf],
                 ['','<3','4','5','>6'], 'log(Win size)','log(Spin initiation latency)',1)

data_crop=data_crop[data_crop.loc[:,'Result']<1200]
plot_hist_for_pop('POP1',data_crop,'Result')
plot_hist_for_pop('POP1',data_crop,'logResult')
plot_hist_for_pop('POP1',data_crop,'Trial.no')
plot_hist_for_pop('POP1',data_crop,'sqrtTrial.no')
plot_hist_for_pop('POP1',data_crop,'Final.balance')
plot_hist_for_pop('POP1',data_crop,'logISI')
plot_hist_for_pop('POP1',data_crop,'ISIms')
