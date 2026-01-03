from flask import Flask, jsonify, render_template, send_from_directory
from disk_monitor import DiskMonitor
import os

app = Flask(__name__)

# Check if we should use dummy data (e.g. if not root or explicitly set)
USE_DUMMY = os.environ.get("SNOKNAS_DUMMY", "False").lower() == "true" or os.geteuid() != 0
monitor = DiskMonitor(use_dummy=USE_DUMMY)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/disks')
def get_disks():
    disks = monitor.get_system_disks()
    return jsonify(disks=disks)

@app.route('/api/system')
def get_system():
    # Placeholder for system stats (CPU/RAM)
    import psutil
    import socket
    import platform
    import time

    uptime_seconds = time.time() - psutil.boot_time()
    uptime_string = time.strftime("%H:%M:%S", time.gmtime(uptime_seconds))

    return jsonify({
        "cpu_percent": psutil.cpu_percent(),
        "memory_percent": psutil.virtual_memory().percent,
        "mode": "Dummy" if monitor.use_dummy else "Live",
        "hostname": socket.gethostname(),
        "platform": platform.system(),
        "version": platform.release(),
        "uptime": uptime_string,
        "os": "SnokOS/Linux"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
