#!/usr/bin/python3

'''
dim_keyboard. Automatic keyboard dimmer.

Usage:
  dim_keyboard [options] <timeout>

Options:
  --interval <n>  User activity polling interval (s). [default: 1]
'''

import sys
import time
from sh import xprintidle
import docopt


__version__ = '0.0'

ASUS_FN = '/sys/class/leds/asus::kbd_backlight/brightness'


def asus_get_brightness(fn):
	with open(fn, 'r') as f:
		return int(f.read())


def asus_set_brightness(fn, level):
	with open(fn, 'w') as f:
		f.write('%d' % level)


def main():
	print('starting')
	args = docopt.docopt(__doc__, version=__version__)

	timeout = float(args['<timeout>'])
	interval = float(args['--interval'])
	print('timeout: %s, interval: %s' % (timeout, interval))

	was_idle = False

	level_saved = asus_get_brightness(ASUS_FN)
	print('initial keyboard brigtness level is %s' % level_saved)

	try:
		while 1:
			level = asus_get_brightness(ASUS_FN)
			idle = int(xprintidle()) / 1000
			is_idle = idle >= timeout

			if is_idle and not was_idle:
				print('user is now idle')
				level_saved = level
				if level != 0:
					print('dimming keyboard from level %s' % level_saved)
					asus_set_brightness(ASUS_FN, 0)
			elif not is_idle and was_idle:
				print('user is now active')
				if level != level_saved:
					print('restoring keyboard brightness level to %s' % level_saved)
					asus_set_brightness(ASUS_FN, level_saved)

			was_idle = is_idle

			time.sleep(interval)
	except KeyboardInterrupt:
		pass

	print('exit')


if __name__ == '__main__':
	main()
