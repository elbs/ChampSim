#!/usr/bin/env python

import sys
import csv
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import cm
import math

# Read CSV
df = pd.read_csv(sys.argv[1])

# Store which prefetcher is this
prefetcher=df['prefetcher'][0]
replpol=df['replpol'][0]
output_file = prefetcher+"_"+replpol+".png"

# Remove prefetcher column, is the same for the whole CSV
del df['prefetcher']
del df['replpol']

# Pivot table
table = pd.pivot_table(df, 
                       values='speedup', 
                       index='trace', 
                       columns='inclusivity')
                       #columns='replpol')

table = table.reindex(df['trace'].unique())

# Find min and max speedups to set y axis
speedup_min = df['speedup'].min()
speedup_max = df['speedup'].max()
miny = speedup_min - 0.1
maxy = speedup_max + 0.1

#print miny
#print maxy

miny=math.floor(miny*10)/10
maxy=math.ceil(maxy*10)/10

#print miny
#print maxy


# Generate plot
ax = table.plot(kind='bar', 
         title="1 core: "+"Prefetcher '"+prefetcher+"' "+"ReplPol '"+replpol+"'",
         colormap=cm.get_cmap('gist_rainbow'),
         figsize=(12,6),
         ylim=(miny, maxy)
         );


# Plot configuration

  # Do not display those axis lines
ax.spines["top"].set_visible(False)    
ax.spines["right"].set_visible(False) 

  # Set Y axis title
ax.set_ylabel('Speedup')
ax.set_xlabel('Benchmarks')

  # Display only bottom and left ticks
ax.get_xaxis().tick_bottom()    
ax.get_yaxis().tick_left()

  # Set grid lines
ax.yaxis.grid(b=True, which='major', color='b', linestyle='--', alpha=0.2)

  # Remove legend title
plt.legend(title="")

patches, labels = ax.get_legend_handles_labels()
ax.legend(patches, labels, loc='best')



# Save plot
plt.savefig(output_file, bbox_inches='tight')

# Show plot
#plt.show()
