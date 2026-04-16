import argparse
import io
import os

import pytesseract
from PIL import Image, ImageOps


class TextExtractor:
    def __init__(self, lang="en"):
        self.lang = lang
        tesseract_cmd = os.getenv("TESSERACT_CMD")
        if tesseract_cmd:
            pytesseract.pytesseract.tesseract_cmd = tesseract_cmd

    def read_text(self, image_bytes: bytes):
        if not image_bytes:
            print("no image data provided")
            return []

        try:
            image = Image.open(io.BytesIO(image_bytes))
        except Exception:
            print("unable to decode image bytes")
            return []

        preprocessed = self.preprocess_image(image)
        extracted_text = pytesseract.image_to_string(preprocessed, lang=self.lang).strip()
        return [extracted_text] if extracted_text else []

    def preprocess_image(self, image):
        gray = ImageOps.grayscale(image)
        # Simple binarization boosts OCR quality while keeping dependencies minimal.
        return gray.point(lambda p: 255 if p > 160 else 0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract text from an image using Tesseract OCR")
    parser.add_argument("filepath", help="Path to input image")
    args = parser.parse_args()

    input_path = os.path.abspath(args.filepath)
    if not os.path.exists(input_path):
        print(f"file not found: {input_path}")
        raise SystemExit(1)

    extractor = TextExtractor()
    with open(input_path, "rb") as image_file:
        image_bytes = image_file.read()

    text_list = extractor.read_text(image_bytes)

    print(text_list)
