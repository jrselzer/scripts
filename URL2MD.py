import re
import requests
from bs4 import BeautifulSoup
import trafilatura
from urllib.parse import urlparse
from time import sleep

INPUT_FILE = "ki-links.txt"
OUTPUT_FILE = "ki-links.md"

HEADERS = {
    "User-Agent": "Mozilla/5.0"
}


def extract_urls(text):
    pattern = r'https?://[^\s]+'
    return re.findall(pattern, text)


def clean_text(text):
    if not text:
        return ""

    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def fetch_page(url):
    try:
        response = requests.get(url, headers=HEADERS, timeout=20)
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"Fehler bei {url}: {e}")
        return None


def extract_title_and_intro(html, url):
    try:
        downloaded = trafilatura.extract(
            html,
            include_comments=False,
            include_tables=False,
            favor_precision=True,
            output_format="txt"
        )

        soup = BeautifulSoup(html, "lxml")

        title = None

        if soup.title and soup.title.text:
            title = clean_text(soup.title.text)

        if not title:
            h1 = soup.find("h1")
            if h1:
                title = clean_text(h1.get_text())

        if not title:
print(f"\nFertig. Ausgabe gespeichert in: {OUTPUT_FILE}")
