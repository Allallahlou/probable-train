from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId

app = FastAPI()

# إعداد الاتصال بقاعدة البيانات
client = AsyncIOMotorClient("mongodb://localhost:27017")
db = client.noteapp
notes_collection = db.notes

# لتحويل ObjectId إلى str
class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

# نموذج البيانات
class Note(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    title: str
    content: Optional[str] = ""
    is_favorite: bool = False
    is_deleted: bool = False

    
class Config:
    validate_by_name = True  # بدل allow_population_by_field_name = True


# ✅ جلب الملاحظات
@app.get("/notes", response_model=List[Note])
async def get_notes():
    notes = await notes_collection.find({"is_deleted": False}).to_list(100)
    return notes

# ✅ إضافة ملاحظة
@app.post("/notes", response_model=Note)
async def add_note(note: Note):
    note_dict = note.dict(by_alias=True, exclude={"id"})
    result = await notes_collection.insert_one(note_dict)
    new_note = await notes_collection.find_one({"_id": result.inserted_id})
    return new_note
