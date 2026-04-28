from fastapi import FastAPI
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from pydantic import BaseModel

SQLALCHEMY_DATABASE_URL = "sqlite:///./med_data.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
app = FastAPI(title="Telematyka Medyczna API")

class MeasurementCreate(BaseModel):
    visit_id: int
    blood_pressure_sys: int
    blood_pressure_dia: int
    heart_rate: int
    glucose_level: float
    notes: str | None = None

class VisitUpdate(BaseModel):
    visit_id: int
    new_date: str

class NewVisit(BaseModel):
    patient_id: int
    visit_date: str

class LoginRequest(BaseModel):
    username: str
    password: str
    role: str

@app.post("/login/")
def login(auth: LoginRequest):
    db = SessionLocal()
    try:
        query = text("""
            SELECT username, role, full_name 
            FROM users 
            WHERE username = :u AND password = :p AND role = :r
        """)
        result = db.execute(query, {"u": auth.username, "p": auth.password, "r": auth.role}).fetchone()
        
        if result:
            return {"status": "success", "user": dict(result._mapping)}
        return {"status": "error", "message": "Niepoprawne dane"}
    finally:
        db.close()

@app.get("/patients-with-visits/")
def get_patients_with_visits():
    db = SessionLocal()
    try:
        query = text("""
            SELECT p.*, v.id AS visit_id, v.visit_date, v.status AS visit_status
            FROM patients p
            JOIN visits v ON p.id = v.patient_id
            WHERE v.status = 'Zaplanowana'
            ORDER BY v.visit_date ASC
        """)
        result = db.execute(query).fetchall()
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

@app.post("/measurements/")
def create_measurement(m: MeasurementCreate):
    db = SessionLocal()
    try:
        query_metrics = text("""
            INSERT INTO health_metrics 
            (visit_id, blood_pressure_sys, blood_pressure_dia, heart_rate, glucose_level, notes)
            VALUES (:v_id, :sys, :dia, :hr, :glu, :notes)
        """)
        db.execute(query_metrics, {
            "v_id": m.visit_id, "sys": m.blood_pressure_sys, "dia": m.blood_pressure_dia,
            "hr": m.heart_rate, "glu": m.glucose_level, "notes": m.notes,
        })

        db.execute(
            text("UPDATE visits SET status = 'Zakończona' WHERE id = :v_id"),
            {"v_id": m.visit_id}
        )
        
        db.commit()
        return {"status": "success", "message": "Zapisano i zakończono wizytę"}
    except Exception as e:
        db.rollback()
        return {"status": "error", "message": str(e)}
    finally:
        db.close()

@app.put("/update-visit-date/")
def update_visit_date(data: VisitUpdate):
    db = SessionLocal()
    try:
        query = text("UPDATE visits SET visit_date = :new_date WHERE id = :v_id")
        db.execute(query, {"new_date": data.new_date, "v_id": data.visit_id})
        db.commit()
        return {"status": "success", "message": "Termin zaktualizowany"}
    except Exception as e:
        db.rollback()
        return {"status": "error", "message": str(e)}
    finally:
        db.close()

@app.post("/create-visit/")
def create_visit(v: NewVisit):
    db = SessionLocal()
    try:
        query = text("""
            INSERT INTO visits (patient_id, visit_date, status)
            VALUES (:p_id, :v_date, 'Zaplanowana')
        """)
        db.execute(query, {"p_id": v.patient_id, "v_date": v.visit_date})
        db.commit()
        return {"status": "success"}
    finally:
        db.close()

@app.get("/patient-history/{pesel}")
def get_patient_history(pesel: str):
    db = SessionLocal()
    try:
        query = text("""
            SELECT 
                p.first_name, p.last_name, p.pesel, p.address, p.allergies, p.chronic_diseases,
                v.visit_date,
                hm.blood_pressure_sys, hm.blood_pressure_dia, hm.heart_rate, hm.glucose_level, hm.notes
            FROM patients p
            JOIN visits v ON p.id = v.patient_id
            LEFT JOIN health_metrics hm ON v.id = hm.visit_id
            WHERE p.pesel = :pesel AND v.status = 'Zakończona'
            ORDER BY v.visit_date DESC
        """)
        result = db.execute(query, {"pesel": pesel}).fetchall()
        return [dict(row._mapping) for row in result]
    finally:
        db.close()