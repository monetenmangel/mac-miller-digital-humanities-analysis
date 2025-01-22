from load import GeniusAPI, ScrapeSongs
import pandas as pd
import os
import time

startzeit = time.time() # Startzeit des Skripts, um zu messen wie lange es braucht

ARTIST_ID = 820 # Mac Millers Artist ID on Genius

genius_api_token = GeniusAPI.get_access_token()
artist_songs = GeniusAPI.get_artist_songs(ARTIST_ID, genius_api_token)
print("List with song URLs is finished")

df = ScrapeSongs.scrape_all_lyrics(artist_songs)


output_dir = os.path.join(os.getcwd(), "output")

# CSV-Datei im "output"-Ordner speichern
output_path = os.path.join(output_dir, "lyrics.csv")
df.to_csv(output_path, index=False, encoding="utf-8")

endzeit = time.time()

print(f"Success! Laufzeit: {endzeit - startzeit:.6f} Sekunden")
