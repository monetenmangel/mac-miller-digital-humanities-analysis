from load import GeniusAPI, ScrapeSongs
import pandas as pd
import os
import time

start = time.time()

ARTIST_ID = 820 # Mac Millers Artist ID on Genius

# Get list of all tracks, that Genius knows for Mac Miller
genius_api_token = GeniusAPI.get_access_token()
artist_songs = GeniusAPI.get_artist_songs(ARTIST_ID, genius_api_token)
print("List with song URLs is finished")

# Scrape the lyrics for all found tracks
df = ScrapeSongs.scrape_all_lyrics(artist_songs)

# Save results in csv
output_dir = os.path.join(os.getcwd(), "output")
output_path = os.path.join(output_dir, "lyrics.json")
df.to_(output_path, orient = 'split', compression = 'infer', index = 'true')

end = time.time()

print(f"Success! Runtime: {end - start:.6f} seconds")
