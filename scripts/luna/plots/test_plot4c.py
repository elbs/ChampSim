#!/usr/bin/env python

import sys
import csv
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import cm
import math
from scipy.stats import gmean


# Read CSV
df = pd.read_csv(sys.argv[1])

trace = df.trace.unique()
dfc = df[df['metric'] == 'ipc']

#print dfc

dfps=[]
#trace data preparation
for t in trace:
  #print t
  dftc = dfc[dfc['trace'] == t]

  dfp = pd.pivot_table(dftc,index=['l1p','l2p','repl'], columns='inc', values='value')
  #print dfp
  dfps.append({'title': t,'data': dfp})

#gmean data preparation
#print 'gmean'
dfca = dfc.groupby(['l1p','l2p','repl','inc']).agg(lambda x: gmean(list(x)))
dfca = dfca.reset_index()
dfp = pd.pivot_table(dfca, index=['l1p','l2p','repl'], columns='inc', values='value')
dfps.append({'title': 'gmean', 'data': dfp})
#print dfp

for dfpd in dfps:
  t = dfpd['title']
  dfp = dfpd['data']
  dfp.EXC = dfp.EXC/dfp.get_value(('next_line','no','lru'), 'NON')
  dfp.INC = dfp.INC/dfp.get_value(('next_line','no','lru'), 'NON')
  dfp.NON = dfp.NON/dfp.get_value(('next_line','no','lru'), 'NON')

  if t == "gmean":
    print dfp

  ax = dfp.plot(kind='bar',figsize=(14,6), grid=True)

  ax.set_title(t)
  ax.set_ylim(ymin=0.9,ymax=2)
  #ax.set_ylim(ymin=0,ymax=1)
  ax.axhline(y=1)
  ax.set_xticklabels(ax.xaxis.get_majorticklabels(), rotation=45,ha='right')
  #ax.set_ylabel('Average IPC')
  ax.set_ylabel('Speedup')
  # Save plot
  plt.savefig(t+"4c.png", bbox_inches='tight')
