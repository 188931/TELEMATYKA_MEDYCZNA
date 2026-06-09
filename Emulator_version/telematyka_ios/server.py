"""
Telematyka Medyczna - Serwer demonstracyjny
============================================
Uruchomienie:
    pip install fastapi uvicorn sqlalchemy
    python server.py

Serwer startuje na http://127.0.0.1:8000
Dokumentacja: http://127.0.0.1:8000/docs
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from pydantic import BaseModel
from typing import Optional
import random
import uvicorn

# ---------------------------------------------------------------------------
# Baza danych - Twoja istniejąca med_data.db
# ---------------------------------------------------------------------------

SQLALCHEMY_DATABASE_URL = "sqlite:///./med_data.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

app = FastAPI(title="Telematyka Medyczna API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Modele Pydantic (zgodne z VisitPayloads.swift i Twoim istniejącym app.py)
# ---------------------------------------------------------------------------

class LoginRequest(BaseModel):
    username: str
    password: str
    role: str

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

# ---------------------------------------------------------------------------
# Endpointy - identyczne z Twoim app.py (bez zmian)
# ---------------------------------------------------------------------------

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
        db.execute(text("""
            INSERT INTO health_metrics
                (visit_id, blood_pressure_sys, blood_pressure_dia, heart_rate, glucose_level, notes)
            VALUES (:v_id, :sys, :dia, :hr, :glu, :notes)
        """), {"v_id": m.visit_id, "sys": m.blood_pressure_sys, "dia": m.blood_pressure_dia,
               "hr": m.heart_rate, "glu": m.glucose_level, "notes": m.notes})
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
        db.execute(
            text("UPDATE visits SET visit_date = :new_date WHERE id = :v_id"),
            {"new_date": data.new_date, "v_id": data.visit_id}
        )
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
        db.execute(text("""
            INSERT INTO visits (patient_id, visit_date, status)
            VALUES (:p_id, :v_date, 'Zaplanowana')
        """), {"p_id": v.patient_id, "v_date": v.visit_date})
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


# ---------------------------------------------------------------------------
# EMULATOR CIŚNIENIOMIERZA - nowy endpoint
# POST /simulate-bp/
#
# Symuluje pomiar metodą Korotkowa (pompowanie → opuszczanie → wynik).
# Zwraca listę kroków które Swift odtwarza krok po kroku z opóźnieniami.
# Wynik końcowy (step="done") zawiera result_sys/dia/hr gotowe do wpisania.
# ---------------------------------------------------------------------------

@app.post("/simulate-bp/")
def simulate_bp():
    # Realistyczne wartości losowane przy każdym pomiarze
    target_sys = random.randint(110, 155)
    target_dia = random.randint(70, 95)
    target_hr  = random.randint(60, 90)
    max_inflate = target_sys + random.randint(20, 35)

    steps = []

    # Faza 1: Pompowanie mankietu (0 → max_inflate co 10 mmHg)
    for val in range(0, max_inflate + 1, 10):
        steps.append({
            "step": "inflating",
            "display_value": val,
            "message": f"Pompowanie... {val} mmHg",
            "result_sys": None,
            "result_dia": None,
            "result_hr":  None,
            "delay_ms": 120,
        })

    # Faza 2: Opuszczanie - detekcja punktów Korotkowa
    sys_detected = False
    dia_detected = False
    current = max_inflate
    while current > 30:
        msg = f"Pomiar... {current} mmHg"
        if not sys_detected and current <= target_sys:
            sys_detected = True
            msg = f"Wykryto skurczowe: {target_sys} mmHg"
        if not dia_detected and current <= target_dia:
            dia_detected = True
            msg = f"Wykryto rozkurczowe: {target_dia} mmHg"
        steps.append({
            "step": "deflating",
            "display_value": current,
            "message": msg,
            "result_sys": None,
            "result_dia": None,
            "result_hr":  None,
            "delay_ms": 80,
        })
        current -= 2

    # Faza 3: Wynik końcowy
    steps.append({
        "step": "done",
        "display_value": target_sys,
        "message": f"Wynik: {target_sys}/{target_dia} mmHg  •  tętno {target_hr} bpm",
        "result_sys": target_sys,
        "result_dia": target_dia,
        "result_hr":  target_hr,
        "delay_ms": 0,
    })

    return {"steps": steps}


# ---------------------------------------------------------------------------
# Uruchomienie
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 55)
    print("  Telematyka Medyczna  •  http://127.0.0.1:8000")
    print("  Swagger UI           •  http://127.0.0.1:8000/docs")
    print("=" * 55)
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")