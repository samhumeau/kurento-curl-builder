#!/bin/bash -x
set -e

if [ -n "$KMS_TURN_URL" ]; then
  echo "turnURL=$KMS_TURN_URL" > /app/kms-omni-build/kms-elements/src/server/config/WebRtcEndpoint.conf.ini
fi

if [ -n "$KMS_STUN_IP" -a -n "$KMS_STUN_PORT" ]; then
  # Generate WebRtcEndpoint configuration
  echo "stunServerAddress=$KMS_STUN_IP" > /app/kms-omni-build/kms-elements/src/server/config/WebRtcEndpoint.conf.ini
  echo "stunServerPort=$KMS_STUN_PORT" >> /app/kms-omni-build/kms-elements/src/server/config/WebRtcEndpoint.conf.ini
fi

# Remove ipv6 local loop until ipv6 is supported
cat /etc/hosts | sed '/::1/d' | tee /etc/hosts > /dev/null

exec kurento-media-server/server/kurento-media-server --modules-path=. --modules-config-path=./config --conf-file=./config/kurento.conf.json --gst-plugin-path=.

