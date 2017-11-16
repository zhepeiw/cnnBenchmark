import numpy as np
import pandas as pd

info_csv = './data_creation.csv'
artist = 'maroon5'
artist = artist.lower().replace(" ", "")

df = pd.read_csv(info_csv)
df_filtered = df.query('artist=="' + artist + '"')

outfile = './' + artist + '_timelist.csv'
df_out = pd.DataFrame(np.zeros((len(df_filtered), 2)))
df_out.iloc[:, 0] = np.array(df_filtered.iloc[:, 3])
df_out.iloc[:, 1] = np.array(df_filtered.iloc[:, 4])
print(df_out)
df_out.to_csv(outfile, header=False, index=False)
