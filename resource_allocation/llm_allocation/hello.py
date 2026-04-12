from google import genai

client = genai.Client(api_key="AIzaSyCXPXtLjzpQe29nB1s96hO-1l4vn7WOqDA")

for m in client.models.list():
    print(m.name)
