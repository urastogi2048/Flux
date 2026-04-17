import filetype
from pdf2image import convert_from_bytes
from PIL import Image, ImageOps
import pytesseract
import os
import io
import argparse


class TextExtractor:
    def __init__(self, lang="eng"):
        self.lang = lang

        pytesseract.pytesseract.tesseract_cmd = os.getenv(
            "TESSERACT_CMD",
            r"C:\Program Files\Tesseract-OCR\tesseract.exe"
        )

    def read_text(self, file_bytes: bytes, file_type: str):
        if not file_bytes:
            print("No data provided")
            return []

        if file_type == "application/pdf":
            return self.read_pdf(file_bytes)
        else:
            return self.read_image(file_bytes)

    def read_image(self, image_bytes: bytes):
        try:
            image = Image.open(io.BytesIO(image_bytes))
        except Exception:
            print("Unable to decode image bytes")
            return []

        preprocessed = self.preprocess_image(image)

        text = pytesseract.image_to_string(
            preprocessed,
            lang=self.lang
        ).strip()

        return [text] if text else []

    def read_pdf(self, pdf_bytes: bytes):
        try:
            images = convert_from_bytes(
                pdf_bytes,
                dpi=300,
                poppler_path=r"C:\poppler\Library\bin"
            )
        except Exception as e:
            print(f"Unable to convert pdf: {e}")
            return []

        all_text = []

        for i, img in enumerate(images):
            preprocessed = self.preprocess_image(img)

            text = pytesseract.image_to_string(
                preprocessed,
                lang=self.lang
            ).strip()

            if text:
                all_text.append(text)

        return all_text

    def preprocess_image(self, image):
        gray = ImageOps.grayscale(image)

        return gray.point(lambda p: 255 if p > 140 else 0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract text from image/PDF using OCR"
    )
    parser.add_argument("filepath", help="Path to input file")
    args = parser.parse_args()

    input_path = os.path.abspath(args.filepath)

    if not os.path.exists(input_path):
        print(f"File not found: {input_path}")
        raise SystemExit(1)

    extractor = TextExtractor()

    with open(input_path, "rb") as f:
        file_bytes = f.read()

    kind = filetype.guess(file_bytes)
    file_type = kind.mime if kind else "unknown"

    print(f"Detected file type: {file_type}")

    text_list = extractor.read_text(file_bytes, file_type)

    print(" Extracted Text")
    for i, text in enumerate(text_list, 1):
        print(f"[Page {i}]\n{text}\n")
