import argparse
import numpy as np
import os

os.environ["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["FLAGS_enable_pir_api"] = "0"

from paddleocr import PaddleOCR
import cv2

class TextExtractor:
    def __init__(self,lang="en"):
        self.ocr=PaddleOCR(
            use_textline_orientation=True,
            lang=lang,
            enable_mkldnn=False,
        )

    def read_text(self,image_bytes:bytes):
        # returns a list with the extracted text for each decoded image.
        text=[]

        if not image_bytes:
            print("no image data provided")
            return []

        image_array=np.frombuffer(image_bytes,dtype=np.uint8)
        img=cv2.imdecode(image_array,cv2.IMREAD_COLOR)
        if img is None:
            print("unable to decode image bytes")
            return []
        
        image=self.preprocess_image(img)

        result=self.ocr.predict(image)
        page_text = []
        if result:
            first_result = result[0]
            if isinstance(first_result, dict) and "rec_texts" in first_result:
                page_text.extend(first_result.get("rec_texts") or [])
            elif isinstance(first_result, list):
                # Backward compatibility with older PaddleOCR output format.
                for line in first_result:
                    text_content = line[1][0]
                    page_text.append(text_content)

        text.append("\n".join(page_text))

        return text
    
    def preprocess_image(self,image):
        if len(image.shape) == 3:
            if image.shape[2] == 4:
                gray = cv2.cvtColor(image, cv2.COLOR_BGRA2GRAY)
            else:
                gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image
        denoised = cv2.fastNlMeansDenoising(gray, h=30)
        thresh = cv2.adaptiveThreshold(
            denoised,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            11,
            2
        )
        return cv2.cvtColor(thresh, cv2.COLOR_GRAY2BGR)

        
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract text from an image using PaddleOCR")
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