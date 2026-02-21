import socket
import struct
import time
import subprocess
import os

class ThreatWeaveHelper:
    """
    chill wrapper for the blazingly fast ocaml engine so python devs 
    don't have to learn monads to correlate network threats.
    """
    def __init__(self, port=13337, auto_start=True):
        self.port = port
        self.ip = "127.0.0.1"
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.proc = None
        
        if auto_start:
            self.start_engine()

    def start_engine(self):
        print("[wrapper] booting up the big brain ocaml engine...")
        # running dune exec in the background. 
        # normally you would compile a linux binary and run that directly.
        script_dir = os.path.dirname(os.path.abspath(__file__))
        self.proc = subprocess.Popen(
            ["dune", "exec", "threatweave", "--", "daemon", str(self.port)],
            cwd=script_dir,
            stdout=subprocess.DEVNULL, # hiding the engine logs so python can be zen
            stderr=subprocess.DEVNULL
        )
        time.sleep(1) # wait for the ocaml server to spin up 

    def yeet_packet(self, payload_bytes: bytes):
        """
        shoves a packet directly into the ocaml engine's mouth via udp.
        the engine will handle the heavy lifting (gadts, async yeeting to DB).
        """
        self.sock.sendto(payload_bytes, (self.ip, self.port))

    def attack_simulation(self, count=1000):
        print(f"[wrapper] simulating incoming ddos. yeeting {count} packets...")
        t0 = time.time()
        for i in range(count):
            # sending fake raw bytes. the ocaml engine will gobble this instantly.
            self.yeet_packet(b"GET /login HTTP/1.1\r\nHost: evil.com\r\n\r\n" * 10)
        t1 = time.time()
        print(f"[wrapper] simulation done in {t1-t0:.4f} secs. ocaml probably didn't even sweat.")

    def close(self):
        if self.proc:
            print("[wrapper] shutting down the ocaml brain.")
            self.proc.terminate()
            self.proc.wait()

if __name__ == "__main__":
    weave = ThreatWeaveHelper(port=13337)
    try:
        weave.attack_simulation(50000)
    finally:
        weave.close()
