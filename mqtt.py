#!/usr/bin/env python

import ssl
import paho.mqtt.client as mqtt

def on_connect(client, userdata, flags, rc):
    print("Connected with result code: " + str(rc))
    client.subscribe('mqtt-msgs')

def on_subscribe(client, userdata, mid, qos):
    print("Subscribed with qos: " + str(qos))

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION1)
client.on_connect = on_connect
client.on_subscribe = on_subscribe

tls_context = ssl.SSLContext(protocol=ssl.PROTOCOL_TLS_CLIENT)

ca_certfile = './certs/ca_certificate.pem'
certfile = './certs/client_shostakovich_certificate.pem'
keyfile = './certs/client_shostakovich_key.pem'

tls_context.load_verify_locations(cafile=ca_certfile)
tls_context.load_cert_chain(certfile, keyfile)
client.tls_set_context(tls_context)

client.connect("localhost", 8883, 60)

client.loop_forever()
