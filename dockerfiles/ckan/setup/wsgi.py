# encoding: utf-8
import os
from ckan.config.middleware import make_app
from werkzeug.middleware.proxy_fix import ProxyFix

config_filepath = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), 'ckan.ini')

application = make_app(config_filepath)

# Trust the X-Forwarded-For, X-Forwarded-Proto and X-Forwarded-Host headers
# set by the nginx reverse proxy. This is required for Flask/WTF-CSRF to
# correctly validate the Referer header against the actual public host.
application = ProxyFix(application, x_for=1, x_proto=1, x_host=1)
