from google import genai
from config import GEMINI_API_KEY
from utils import JSONUtils
import time


class NGOTaskGenerator:

    def __init__(self, model_name: str = "gemini-1.5-pro-latest"):
        self.client = genai.Client(api_key=GEMINI_API_KEY)
        self.model_name = model_name

    def _build_prompt(self, data: dict) -> str:
        return f"""
You are an intelligent NGO task planner.

Generate a practical NGO task.

STRICT RULES:
- Output ONLY valid JSON
- No explanation
- No markdown
- No extra text
- Use double quotes
- All fields must be present

Input:
{data}

Output format:
{{
  "task_id": "",
  "title": "",
  "category": "",
  "location": "",
  "objective": "",
  "required_resources": {{
    "volunteers": 0,
    "skills": [],
    "materials": []
  }},
  "timeline": {{
    "deadline": "",
    "estimated_duration_hours": 0
  }},
  "priority": "",
  "notes": ""
}}
"""

    def generate_task(self, data: dict, retries: int = 3):
        last_raw = ""

        for attempt in range(retries):
            try:
                prompt = self._build_prompt(data)

                response = self.client.models.generate_content(
                    model=self.model_name,
                    contents=prompt,
                    config={
                        "response_mime_type": "application/json"
                    }
                )

                raw_text = response.text
                last_raw = raw_text

                parsed, cleaned = JSONUtils.parse_llm_output(raw_text)

                if parsed:
                    return parsed

            except Exception as e:
                print(f"[LLM ERROR] Attempt {attempt+1}: {e}")

            time.sleep(1)  # small backoff

        return {
            "error": "Failed to generate valid JSON",
            "raw_output": last_raw
        }
