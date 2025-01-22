import requests
from bs4 import BeautifulSoup, Tag
import pandas as pd
from genius_credentials import *

class GeniusAPI:
    
    def get_access_token():
        '''
        Returns Access Token for Genius API
        '''
        client_id = genius_credentials.client_id
        client_secret = genius_credentials.client_secret
        
        data = {
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": "http://localhost",
            "response_type": "code",
            "grant_type": "client_credentials",
        }
        
        response = requests.post("https://api.genius.com/oauth/token", data=data)
        
        if response.status_code == 200:
            access_token = response.json()["access_token"]
            return access_token
        else:
            print(f"Error: {response.status_code}")
            return None
        
    def get_artist_songs(artist_id: int, access_token) -> list:
        '''
        Returns for the chosen artist a list with all the tracks, that are available for this artist
        '''
        base_url = "https://api.genius.com"
        headers = {"Authorization": "Bearer " + access_token}
        songs_url = base_url + f"/artists/{artist_id}/songs"
        params = {
            "sort": "title",
            "per_page": 50,
            "page": 1
        }
        song_urls = []

        while True:
            response = requests.get(songs_url, params=params, headers=headers)
            response.raise_for_status()
            json_response = response.json()
            song_data = json_response["response"]["songs"]

            if not song_data:
                break

            for song in song_data:
                if song["primary_artist"]["id"] == artist_id:  # check if song is by the artist
                    song_urls.append(song["url"])

            params["page"] += 1

        return song_urls

class ScrapeSongs: 

    def get_data_lyrics_container_class(url: str) -> str:
        response = requests.get(url)
        soup = BeautifulSoup(response.text, "html.parser")

        # find div with lyrics container
        div = soup.find("div", {"data-lyrics-container": True})

        div_class = div.get("class")[0]

        return div_class    
    
    def scrape_lyrics(url: str, lyrics_container: str) -> str:
        '''
        Scrapes the html for the specified URL for the lyrics container.
        Parses the results and saves everything in a dict
        '''
        response = requests.get(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        # Scrape the lyrics
        try:
            divs = soup.find_all('div', {'data-lyrics-container': 'true', 'class': lyrics_container})

            for div in divs:
                for br in div.findAll('br'):
                    br.replace_with('\n')
            
            lyrics = " ".join([div.text for div in divs if div is not None])
        except AttributeError:
            print(f"Failed to scrape lyrics from {url}")
            lyrics = None

        return lyrics
    
    def scrape_all_lyrics(urls: list) -> pd.DataFrame:
        data = {}
        lyrics_container = ScrapeSongs.get_data_lyrics_container_class(urls[0])
        for url in urls:
            lyrics = ScrapeSongs.scrape_lyrics(url, lyrics_container)
            data[url] = lyrics
        
        df = pd.DataFrame(list(data.items()), columns=["URL", "Lyrics"])
        
        return df

        
# urls = ["https://genius.com/Mac-miller-100-grandkids-lyrics", "https://genius.com/Mac-miller-1-threw-8-lyrics", "https://genius.com/Mac-miller-2004-lyrics", "https://genius.com/Mac-miller-2009-lyrics"]
# lyrics = ScrapeSongs.scrape_all_lyrics(urls)
# print(lyrics["https://genius.com/Mac-miller-100-grandkids-lyrics"])

# print(GeniusAPI.get_access_token())
# token = GeniusAPI.get_access_token()
# result = GeniusAPI.get_artist_songs(820, token)

# print(result)

# import json
# with open("song_urls.json", "w") as file:
#     json.dump(result, file)