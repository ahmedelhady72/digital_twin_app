from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
from tensorflow import keras
import uvicorn

app = FastAPI()

# 1. تحميل الموديل مرة واحدة عند تشغيل السيرفر
try:
    model = keras.models.load_model("calibrated_model.keras")
    print("✅ Model loaded successfully!")
except Exception as e:
    print(f"❌ Error loading model: {e}")

# 2. تعريف هيكل البيانات المتوقع
class InputData(BaseModel):
    series_data: list  # متوقع قائمة بداخلها 30 قائمة، كل واحدة فيها 16 عنصر

@app.post("/predict")
async def predict(data: InputData):
    try:
        # تحويل البيانات إلى Numpy Array
        arr = np.array(data.series_data, dtype=np.float32)

        # التأكد من الأبعاد (يجب أن تكون 30x16)
        if arr.shape != (30, 16):
            raise HTTPException(status_code=400, detail=f"Expected shape (30, 16), but got {arr.shape}")

        # إضافة بعد الـ Batch لتصبح (1, 30, 16)
        arr = np.expand_dims(arr, axis=0)

        # عمل التوقع
        prediction = model.predict(arr)

        # إرجاع النتيجة (تحويلها لـ float عادي عشان الـ JSON)
        return {
            "prediction": float(prediction[0][0]),
            "status": "success"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 3. لتشغيل السيرفر مباشرة من الكود أو عبر uvicorn
if __name__ == "__main__":
    # تشغيل السيرفر على IP الجهاز ليتيح للموبايل الاتصال به
    uvicorn.run(app, host="0.0.0.0", port=8000)