# encoding: utf-8
import os

# Initialize OpenTelemetry before the CKAN app is created.
# With uWSGI --lazy-apps, this file runs in each worker after fork,
# so each worker gets a fresh gRPC connection and a live exporter thread.
if os.environ.get('OTEL_EXPORTER_OTLP_ENDPOINT'):
    try:
        import opentelemetry.instrumentation.auto_instrumentation.sitecustomize  # noqa: F401
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("[OTel] init failed: %s", e)

from ckan.config.middleware import make_app
from ckan.cli import CKANConfigLoader

if os.environ.get(u'CKAN_INI'):
    config_path = os.environ[u'CKAN_INI']
else:
    config_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), u'ckan.ini'
    )

if not os.path.exists(config_path):
    raise RuntimeError(u'CKAN config file not found: %s' % config_path)

application = make_app(CKANConfigLoader(config_path).get_config())
