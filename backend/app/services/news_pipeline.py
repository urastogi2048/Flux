import hashlib
from typing import Any, Dict, List

import feedparser

HIGH_PRIORITY_WORDS = ["urgent", "blood", "emergency", "critical"]

BASIC_KEYWORDS = [
    "donation",
    "food",
    "flood",
    "earthquake",
    "relief",
    "help",
    "injured",
    "hospital",
    "rescue",
    "victims",
    "accident",
]


def clean_url(url: str) -> str:
    if "url=" in url:
        return url.split("url=")[-1]
    return url


def fetch_news(state: str) -> List[Dict[str, str]]:
    location = state or "India"

    base_queries = [
        "urgent blood donation",
        "flood relief victims",
        "earthquake rescue",
        "road accident injured hospital",
        "food shortage poor",
        "people stranded rescue",
    ]

    queries = [f"{q} {location}" for q in base_queries]
    all_articles: List[Dict[str, str]] = []

    for q in queries:
        url = f"https://news.google.com/rss/search?q={q.replace(' ', '+')}"
        feed = feedparser.parse(url)

        for entry in feed.entries[:5]:
            all_articles.append(
                {
                    "title": entry.title,
                    "description": entry.get("summary", ""),
                    "url": clean_url(entry.link),
                }
            )

    return all_articles


def generate_id(text: str) -> str:
    return hashlib.md5(text.encode()).hexdigest()


def analyze(article: Dict[str, str]):
    text = (article["title"] + " " + (article.get("description") or "")).lower()

    if any(word in text for word in HIGH_PRIORITY_WORDS):
        return True, "HIGH"

    if any(word in text for word in BASIC_KEYWORDS):
        return True, "MEDIUM"

    return False, None


def classify(text: str) -> str:
    lowered = text.lower()

    if "blood" in lowered:
        return "blood_donation"
    if "flood" in lowered or "earthquake" in lowered:
        return "disaster"
    if "food" in lowered:
        return "food"
    return "general"


def process_articles(articles: List[Dict[str, str]]) -> List[Dict[str, str]]:
    alerts: List[Dict[str, str]] = []
    seen_ids = set()

    for article in articles:
        text = article["title"] + " " + (article.get("description") or "")

        alert_id = generate_id(article["url"])
        if alert_id in seen_ids:
            continue
        seen_ids.add(alert_id)

        relevant, priority = analyze(article)
        if not relevant or not priority:
            continue

        alerts.append(
            {
                "title": article["title"],
                "url": article["url"],
                "priority": priority,
                "category": classify(text),
            }
        )

    return alerts


def get_news_alerts_by_state(state: str) -> Dict[str, Any]:
    normalized_state = state.strip()
    articles = fetch_news(normalized_state)
    alerts = process_articles(articles)

    return {
        "state": normalized_state,
        "total_articles_fetched": len(articles),
        "total_alerts": len(alerts),
        "alerts": alerts,
    }
