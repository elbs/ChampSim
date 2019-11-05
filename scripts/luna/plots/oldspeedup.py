#!/usr/bin/env python

import csv
import sys

import pylab as p

fig = p.figure()
ax = fig.add_subplot(1,1,1)

result = dict()
av = []
idx = []
for file in sys.argv[1:]:
    next_av = []
    next_idx = []
    for row in csv.DictReader(open(file)):
      trace = row['trace']
      prefetcher = row['prefetcher']
      replpol = row['replpol']
      speedup = row['speedup']
    
    av.append(next_av)
    idx.append(next_idx)

    y = av
    N = len(y)
    ind = range(N)
    ax.bar(ind, y, facecolor='#56A5EC',
            align='center',label='1 Thread') 
    ax.set_ylabel('Average Response Time')
    ax.set_title('Counts, by group',fontstyle='italic')
    ax.legend()
    ax.set_xticks(trace)
    ax.grid(color='#000000', linestyle=':', linewidth=1)
    group_labels = idx
    ax.set_xticklabels(group_labels)
    fig.autofmt_xdate()  
    p.grid(True) 
    p.show()
