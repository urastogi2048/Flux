from fastapi import FastAPI
from schemas import NGOInput
from llm import NGOTaskGenerator

app = FastAPI()


generator = NGOTaskGenerator()


@app.get("/")
def home():
    return {"message": "NGO AI Task Generator API is running "}


@app.post("/generate-task")
def generate_task(data: NGOInput):
    """
    Generate NGO task based on structured input
    """

    try:

        input_data = data.model_dump()

        # Call LLM
        result = generator.generate_task(input_data)

        # If LLM failed
        if "error" in result:
            return {
                "status": "failure",
                "error": result["error"],
                "raw_output": result.get("raw_output", None)
            }

        # Success
        return {
            "status": "success",
            "data": result
        }

    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }
