#!/usr/bin/python3
# Dumbest possible player. Lifted from: https://pypi.org/project/PyChromecast/
import pychromecast
import sys
import time
services, browser = pychromecast.discovery.discover_chromecasts()
pychromecast.discovery.stop_discovery(browser)
chromecasts, browser = pychromecast.get_listed_chromecasts(friendly_names=["Shower TV"])
cast = chromecasts[0]
cast.wait()
print(cast.device)
print(cast.status)
mc = cast.media_controller
mc.play_media(sys.argv[1], sys.argv[2])
mc.block_until_active()
print(mc.status)
pychromecast.discovery.stop_discovery(browser)
time.sleep(5)
print(mc.status)
time.sleep(15)
print(mc.status)
time.sleep(45)
print(mc.status)
