import json
import re


class JSONUtils:

    @staticmethod
    def extract_json(text: str) -> str:
        text = re.sub(r"```json|```", "", text).strip()

        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            return match.group(0)

        return text

    @staticmethod
    def fix_common_issues(text: str) -> str:
        text = re.sub(r",\s*}", "}", text)
        text = re.sub(r",\s*]", "]", text)
        text = text.replace("'", '"')
        text = text.replace("\n", " ")
        return text

    @staticmethod
    def safe_parse(text: str):
        try:
            return json.loads(text)
        except:
            pass

        try:
            fixed = JSONUtils.fix_common_issues(text)
            return json.loads(fixed)
        except:
            pass

        return None

    @staticmethod
    def parse_llm_output(text: str):
        extracted = JSONUtils.extract_json(text)
        parsed = JSONUtils.safe_parse(extracted)

        return parsed, extracted
