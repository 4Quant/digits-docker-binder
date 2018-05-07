import os
import digits, digits.webapp
import argparse

parser = argparse.ArgumentParser(description='DIGITS server')

parser.add_argument(
    '-p', '--port',
    type=int,
    default=5000,
    help='Port to run app on (default 5000)'
)
args = vars(parser.parse_args())
base_prefix = '{}proxy/{}/'.format(os.environ['JUPYTERHUB_SERVICE_PREFIX'], args['port'])
digits.webapp.app.debug = False
# binder specific code to make url_for work correctly
class FixScriptName(object):
    def __init__(self, app, prefix):
        self.app = app
        self.prefix = prefix
    def __call__(self, environ, start_response):
        environ['SCRIPT_NAME'] = self.prefix
        return self.app(environ, start_response)
app2 = FixScriptName(digits.webapp.app, base_prefix)
print('Launching Server', digits.webapp.app.config)
from werkzeug.serving import run_simple
import digits.config
import digits.log

try:
    if not digits.webapp.scheduler.start():
        print 'ERROR: Scheduler would not start'
    else:
        run_simple('0.0.0.0', args['port'], app2, use_reloader=False)
except KeyboardInterrupt:
    pass
finally:
    digits.webapp.scheduler.stop()

