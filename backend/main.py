from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import random
import platform
import psutil
import time

app = FastAPI(
    title="SnokNAS API",
    description="Enterprise API for SnokNAS Storage System",
    version="1.0.0"
)

# CORS Configuration
origins = [
    "http://localhost:5173",  # Vite Dev Server
    "http://localhost:80",    # Production
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Models ---
class Drive(BaseModel):
    id: int
    status: str
    temp: int
    capacity: float
    usage: float
    type: str

class SystemInfo(BaseModel):
    hostname: str
    os: str
    uptime: float
    cpu_percent: float
    memory_total: int
    memory_used: int

# --- Mock Data Simulator ---
def get_mock_drives() -> List[Drive]:
    # In production, this would call smartctl or ZFS python bindings
    drives = []
    for i in range(1, 9):
        status = "healthy"
        temp = random.randint(28, 48)
        if i == 6:
            status = "warning"
            temp = 52
        
        drives.append(Drive(
            id=i,
            status=status,
            temp=temp,
            capacity=4.0,
            usage=random.uniform(0.1, 3.5),
            type="HDD - WD Red Pro"
        ))
    return drives

# --- Endpoints ---

@app.get("/")
def read_root():
    return {"system": "SnokNAS", "status": "online"}

@app.get("/api/system", response_model=SystemInfo)
def get_system_info():
    return SystemInfo(
        hostname=platform.node(),
        os=f"{platform.system()} {platform.release()}",
        uptime=time.time() - psutil.boot_time(),
        cpu_percent=psutil.cpu_percent(),
        memory_total=psutil.virtual_memory().total,
        memory_used=psutil.virtual_memory().used
    )

@app.get("/api/storage/rack", response_model=List[Drive])
def get_rack_status():
    """
    Returns the real-time status of the 8-bay rack.
    Proprietary SnokNAS Technology.
    """
    return get_mock_drives()

@app.post("/api/services/docker/restart")
def restart_docker():
    # In production: subprocess.run(["systemctl", "restart", "docker"])
    return {"status": "restarting", "service": "docker"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
