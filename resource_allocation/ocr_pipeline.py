from enum import Enum,auto
import argparse
import numpy as np
import mimetypes
import os

os.environ["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["FLAGS_enable_pir_api"] = "0"

from paddleocr import PaddleOCR
from pdf2image import convert_from_path
import cv2


class FileCategory(Enum):
    IMAGE=auto()
    PDF=auto()
    UNKNOWN=auto()

def get_file_category(filepath:str)->FileCategory:
    mimetype,_=mimetypes.guess_type(filepath)

    if mimetype=="application/pdf":
        return FileCategory.PDF
    if mimetype and mimetype.startswith("image/"):
        return FileCategory.IMAGE
    
    return FileCategory.UNKNOWN

class TextExtractor:
    def __init__(self,dpi=300,lang="en"):
        self.ocr=PaddleOCR(
            use_textline_orientation=True,
            lang=lang,
            enable_mkldnn=False,
        )
        self.dpi=dpi

    def read_text(self,filepath):
        #returns a list of text extracted..........list contains only 1 string if file_path is an image or contains multiple if file url is pdf
        images=[]
        text=[]

        file_category=get_file_category(filepath)
        if file_category==FileCategory.IMAGE:
            img=cv2.imread(filepath)
            if img is not None:
                images.append(img)
            else:
                print(f"unable to read image: {filepath}")
                return []
        elif file_category==FileCategory.PDF:
            pages=convert_from_path(filepath,dpi=self.dpi)
            for page in pages:
                img=np.array(page)
                images.append(img)
        else:
            print("file type not supported")
            return []
        
        for image in images:
            image=self.preprocess_image(image)

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
    parser = argparse.ArgumentParser(description="Extract text from an image or PDF using PaddleOCR")
    parser.add_argument("filepath", help="Path to input image or PDF")
    args = parser.parse_args()

    input_path = os.path.abspath(args.filepath)
    if not os.path.exists(input_path):
        print(f"file not found: {input_path}")
        raise SystemExit(1)

    extractor = TextExtractor()
    text_list = extractor.read_text(input_path)

    print(text_list)