import feedparser
import hashlib


HIGH_PRIORITY_WORDS = ["urgent", "blood", "emergency", "critical"]

BASIC_KEYWORDS = [
    "donation", "food", "flood", "earthquake", "relief", "help",
    "injured", "hospital", "rescue", "victims", "accident"
]

seen_ids = set()


def clean_url(url):
    if "url=" in url:
        return url.split("url=")[-1]
    return url


def fetch_news(state=None):

    location = state if state else "India"

    base_queries = [
        "urgent blood donation",
        "flood relief victims",
        "earthquake rescue",
        "road accident injured hospital",
        "food shortage poor",
        "people stranded rescue"
    ]

    queries = [f"{q} {location}" for q in base_queries]

    all_articles = []

    for q in queries:
        url = f"https://news.google.com/rss/search?q={q.replace(' ', '+')}"

        feed = feedparser.parse(url)

        print(f"Query: {q} → {len(feed.entries)} results")

        for entry in feed.entries[:5]:
            article = {
                "title": entry.title,
                "description": entry.get("summary", ""),
                "url": clean_url(entry.link)
            }
            all_articles.append(article)

    return all_articles


def generate_id(text):
    return hashlib.md5(text.encode()).hexdigest()


def is_duplicate(alert_id):
    if alert_id in seen_ids:
        return True
    seen_ids.add(alert_id)
    return False


def analyze(article):
    text = (article["title"] + " " +
            (article.get("description") or "")).lower()

    if any(word in text for word in HIGH_PRIORITY_WORDS):
        return True, "HIGH"

    if any(word in text for word in BASIC_KEYWORDS):
        return True, "MEDIUM"

    return False, None


def classify(text):
    text = text.lower()

    if "blood" in text:
        return "blood_donation"
    elif "flood" in text or "earthquake" in text:
        return "disaster"
    elif "food" in text:
        return "food"
    else:
        return "general"


def process_articles(articles):
    alerts = []

    for article in articles:
        text = article["title"] + " " + (article.get("description") or "")

        alert_id = generate_id(article["url"])

        if is_duplicate(alert_id):
            continue

        relevant, priority = analyze(article)

        if relevant:
            category = classify(text)

            alert = {
                "title": article["title"],
                "url": article["url"],
                "priority": priority,
                "category": category
            }

            alerts.append(alert)

    return alerts


def main():

    state = None

    print(f"\nFetching NGO news for: {state if state else 'India'}\n")

    articles = fetch_news(state)

    print(f"\nTotal fetched: {len(articles)} articles")

    alerts = process_articles(articles)

    print("\nNGO ALERTS\n")

    if alerts:
        for a in alerts:
            print(f"[{a['priority']}] ({a['category']}) {a['title']}")
            print(f"🔗 {a['url']}\n")
    else:
        print("No relevant alerts found.")


if __name__ == "__main__":
    main()
