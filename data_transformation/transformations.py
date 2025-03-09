import pandas as pd
import os

def loadLyrics() -> pd.DataFrame:
    output_dir = os.path.join(os.getcwd(), "output")
    output_path = os.path.join(output_dir, "lyrics.csv")
    print(output_path)
    df = pd.read_csv(output_path)
    return df

df = loadLyrics()
print(df)

def removePartLabels(df: pd.DataFrame) -> pd.DataFrame:
    '''
    Alles was in [] ist wird rausgefiltert, 
    '''

'''
Was muss ich machen:

- Alles was in Klammern ist rausfiltern
- Line Breaks rausfiltern
- song aus URL parsen
- Album dazuholen
- Jahr wann Album erschienen ist dazuholen 
'''