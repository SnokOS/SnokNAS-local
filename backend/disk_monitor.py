import subprocess
import json
import logging
import random
import os

logger = logging.getLogger("DiskMonitor")

class DiskMonitor:
    def __init__(self, use_dummy=False):
        self.use_dummy = use_dummy

    def _run_command(self, cmd):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {cmd} - {e}")
            return None
        except FileNotFoundError:
             logger.error(f"Command not found: {cmd[0]}")
             return None

    def get_system_disks(self):
        if self.use_dummy:
            return self._generate_dummy_data()
        
        # 1. Get basic disk info using lsblk
        lsblk_cmd = ["lsblk", "-J", "-o", "NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINT,ROTA,TRAN"]
        output = self._run_command(lsblk_cmd)
        
        if not output:
            return []

        try:
            data = json.loads(output)
            blockdevices = data.get("blockdevices", [])
        except json.JSONDecodeError:
            logger.error("Failed to parse lsblk output")
            return []

        disks = []
        
        # Filter for physical disks (type 'disk')
        for device in blockdevices:
            if device.get("type") != "disk":
                continue
            
            # Skip loop devices
            if "loop" in device.get("name", ""):
                continue

            # Identify interface
            tran = device.get("tran", "unknown").upper() # SATA, NVME, USB
            
            disk_info = {
                "name": device.get("name"),
                "size": device.get("size"),
                "model": device.get("model", "Unknown Model"),
                "serial": device.get("serial", "N/A"),
                "rota": device.get("rota"), # 1 if HDD, 0 if SSD
                "type": "HDD" if device.get("rota") == "1" else "SSD",
                "interface": tran,
                "temp": "N/A",
                "health": "UNKNOWN",
                "smart_status": "Unknown",
                "partitions": device.get("children", [])
            }

            # 2. Get SMART data (Root req)
            smart_data = self._get_smart_data(f"/dev/{device['name']}")
            if smart_data:
                 disk_info.update(smart_data)

            disks.append(disk_info)

        return disks

    def _get_smart_data(self, device_path):
        # smartctl -a -j /dev/sdX
        # We add -n standby to avoid spinning up sleeping disks if possible
        cmd = ["smartctl", "-a", "-j", "-n", "standby", device_path]
        output = self._run_command(cmd)
        
        if not output:
            return {}
            
        try:
            data = json.loads(output)
            
            # Extract Temp
            temp = data.get("temperature", {}).get("current")
            
            # Extract Health
            passed = data.get("smart_status", {}).get("passed")
            health = "GOOD" if passed else "BAD"
            
            # Power on hours
            power_on_hours = data.get("power_on_time", {}).get("hours")

            # Extract detailed attributes if needed for AI analysis (Reallocated sectors etc)
            # For now, we return summary
            
            return {
                "temp": temp if temp else "N/A",
                "health": health,
                "smart_status": "Passed" if passed else "Failed",
                "power_on_hours": power_on_hours
            }
        except json.JSONDecodeError:
            return {}

    def _generate_dummy_data(self):
        """Generates 8 realistic disks for UI testing, representing a full rack"""
        disks = []
        models = ["SnokDrive Titan 16TB", "IronWolf Pro 12TB", "Exos X20", "Samsung 870 EVO"]
        for i in range(8):
            is_ssd = i > 5 # Last 2 are SSD cache
            model = models[3] if is_ssd else random.choice(models[:3])
            
            # Simulate a "hot" disk
            temp = random.randint(32, 45)
            if i == 2: temp = 56 # Overheating simulation
            
            health = "GOOD"
            if i == 5: health = "WARNING" # Degraded drive simulation

            disks.append({
                "name": f"sd{chr(97+i)}",
                "size": "4 TB" if is_ssd else "16 TB",
                "model": model,
                "serial": f"SNK-{random.randint(10000,99999)}-X{i}",
                "type": "SSD" if is_ssd else "HDD",
                "interface": "SATA",
                "temp": temp,
                "health": health,
                "smart_status": "Passed" if health == "GOOD" else "Degraded",
                "power_on_hours": random.randint(5000, 45000)
            })
        return disks

if __name__ == "__main__":
    # Test run
    logging.basicConfig(level=logging.INFO)
    monitor = DiskMonitor(use_dummy=True)
    print(json.dumps(monitor.get_system_disks(), indent=2))
