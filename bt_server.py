#!/usr/bin/env python3
"""
UDPCore BT Server — all-in-one Bluetooth SPP receiver
Usage: sudo python3 bt_server.py
"""

import os, sys, time, signal, threading, subprocess
import bluetooth

CHANNEL    = 1
COMPAT_CFG = '/etc/systemd/system/bluetooth.service.d/compat.conf'

# ── helpers ───────────────────────────────────────────────────────────────────

def run(*cmd, timeout=10):
    return subprocess.run(list(cmd), capture_output=True, text=True, timeout=timeout)

def ok(msg):   print(f"\033[32m[✓]\033[0m {msg}")
def info(msg): print(f"\033[34m[~]\033[0m {msg}")
def warn(msg): print(f"\033[33m[!]\033[0m {msg}")
def die(msg):  sys.exit(f"\033[31m[✗]\033[0m {msg}")

# ── setup ─────────────────────────────────────────────────────────────────────

def ensure_root():
    if os.geteuid() != 0:
        die("Must run as root:  sudo python3 bt_server.py")

def ensure_compat_mode():
    if '--compat' in run('ps', 'aux').stdout:
        ok("bluetoothd already in compat mode")
        return
    info("Enabling bluetoothd --compat (one-time systemd override)...")
    os.makedirs(os.path.dirname(COMPAT_CFG), exist_ok=True)
    with open(COMPAT_CFG, 'w') as f:
        f.write("[Service]\nExecStart=\nExecStart=/usr/lib/bluetooth/bluetoothd --compat\n")
    run('systemctl', 'daemon-reload')
    run('systemctl', 'restart', 'bluetooth')
    time.sleep(3)  # wait for dbus to settle fully
    ok("bluetoothd restarted with --compat")

def adapter_up():
    """
    Use hciconfig (HCI-level, no dbus) to power on and make discoverable/pairable.
    Much more reliable than going through bluetoothd dbus right after a restart.
    """
    run('hciconfig', 'hci0', 'up')
    time.sleep(0.5)
    run('hciconfig', 'hci0', 'piscan')   # piscan = page scan (pairable) + inquiry scan (discoverable)
    ok("Adapter powered on and discoverable")

def get_adapter_address():
    """Read MAC address via hciconfig — no dbus, always works."""
    out = run('hciconfig', 'hci0').stdout
    for line in out.splitlines():
        if 'BD Address:' in line:
            return line.split('BD Address:')[1].split()[0]
    return '??:??:??:??:??:??'

def start_agent():
    """
    Spawn a background bluetoothctl process solely for the pairing agent.
    NoInputNoOutput = auto-accept all pair requests, no PIN needed.
    Isolated from the main thread so it doesn't block socket calls.
    """
    proc = subprocess.Popen(
        ['bluetoothctl'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    # Send agent setup commands
    for cmd in ('agent NoInputNoOutput', 'default-agent'):
        proc.stdin.write(cmd + '\n')
        proc.stdin.flush()
        time.sleep(0.3)

    # Background reader — surfaces pairing events to stdout
    def _watch():
        keywords = ('Pairing', 'Paired', 'Connected', 'Disconnected', 'Authorize', 'Device')
        try:
            for line in proc.stdout:
                line = line.strip()
                if line and any(k in line for k in keywords):
                    info(f"bt: {line}")
        except Exception:
            pass

    threading.Thread(target=_watch, daemon=True).start()
    return proc

def register_spp():
    r = run('sdptool', 'add', f'--channel={CHANNEL}', 'SP')
    if 'failed' in (r.stderr + r.stdout).lower():
        warn(f"sdptool: {r.stderr.strip()}")
    else:
        ok(f"SPP profile registered on channel {CHANNEL}")

# ── server loop ───────────────────────────────────────────────────────────────

def serve(addr):
    server_sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
    server_sock.bind(('', CHANNEL))
    server_sock.listen(1)

    print()
    ok(f"Adapter  : {addr}")
    ok(f"Listening: RFCOMM channel {CHANNEL}")
    print()
    print("  On the app:")
    print("    1. Toggle to Bluetooth (top-center switch)")
    print("    2. Gear icon → Scan → Pair this machine → Connect")
    print("    3. Hold a direction button — commands appear below")
    print()
    print("  Press Ctrl+C to quit\n")

    try:
        bluetooth.advertise_service(
            server_sock, 'UDPCore-SPP',
            service_classes=[bluetooth.SERIAL_PORT_CLASS],
            profiles=[bluetooth.SERIAL_PORT_PROFILE],
        )
        ok("SDP service advertised\n")
    except bluetooth.BluetoothError:
        warn("SDP advertise skipped — connect by address after pairing\n")

    while True:
        info("Waiting for connection...")
        try:
            client_sock, client_addr = server_sock.accept()
        except KeyboardInterrupt:
            break
        except bluetooth.BluetoothError as e:
            warn(f"Accept error: {e}")
            time.sleep(1)
            continue

        ok(f"Connected: {client_addr[0]}\n")
        try:
            while True:
                data = client_sock.recv(1024)
                if not data:
                    break
                cmd = data.decode('utf-8', errors='replace').strip()
                if cmd:
                    print(f"  \033[36mCMD\033[0m ▶  {cmd}", flush=True)
        except (bluetooth.BluetoothError, OSError):
            pass
        finally:
            client_sock.close()
            print()
            info("Disconnected — waiting for next connection...\n")

    server_sock.close()

# ── entry point ───────────────────────────────────────────────────────────────

def main():
    ensure_root()

    agent_proc = None

    def _cleanup(sig=None, frame=None):
        print()
        info("Shutting down...")
        run('hciconfig', 'hci0', 'noscan')   # stop being discoverable
        if agent_proc:
            agent_proc.terminate()
        sys.exit(0)

    signal.signal(signal.SIGINT,  _cleanup)
    signal.signal(signal.SIGTERM, _cleanup)

    print("\n\033[1mUDPCore BT Server\033[0m")
    print("─" * 40)

    ensure_compat_mode()   # writes systemd override once, restarts bluetoothd
    adapter_up()           # hciconfig — no dbus, immediate
    addr = get_adapter_address()
    agent_proc = start_agent()   # bluetoothctl agent only, isolated
    time.sleep(0.5)
    register_spp()

    serve(addr)
    _cleanup()

if __name__ == '__main__':
    main()
