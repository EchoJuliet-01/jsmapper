#!/usr/bin/python3.8

import socket
import json
import time
import random
from threading import Thread

s=socket.socket()
#host='10.1.1.141'
host='localhost'
port=2442

info=False
a_stations={}
last_info=time.time()
last_sent_pir=last_info
ack=False
grid="DM79"
my_call="N0GQ"

s.connect((host,port))
s.settimeout(1)

def send_message(message):
    global s
    s.sendall(bytes(json.dumps({'params': {}, 'type': 'TX.SEND_MESSAGE', 'value': message})+"\r\n",'utf-8'))
    return

def rx_thread(name):
    global info
    global s
    global a_stations
    global last_info
    global last_sent_pir
    global ack
    print ("Starting " + name)
    n=0
    while True:
        try:
            raw=s.recv(1024).strip()
            stuff=json.loads(raw)
            if 'type' in stuff:
                if(stuff['type']=='RX.DIRECTED'):
                    msg_type=stuff['type']
                    text=stuff['value']
                    params=stuff['params']
                    value=stuff['value']
                    from_call=params['FROM']
                    to_call=params['TO']
                    freq=params['FREQ']/1000
                    snr=params['SNR']
                    speed=params['SPEED']
                    drift=int(params['TDRIFT']*1000)
                    grid=params['GRID']
                    time_t=params['UTC']/1000
                    time_s=time.asctime(time.gmtime(time_t))
                    print("Time: " + time_s)
                    print("From: " + from_call)
                    print("To: " + to_call)
                    print("Freq: " + str(freq) + " khz")
                    print("SNR: " + str(snr))
                    print("Speed: " + str(speed))
                    print("Drift: " + str(drift) + " ms")
                    print("Grid: " + grid)
                    print("Value: " + value)
                    print()
                    tmp=value.split()
                    if(len(tmp)>=4):
                        if((tmp[1]==my_call) and (tmp[2]=="ACK")):
                            ack=True
                    if("/A" in from_call):
                        a_stations[from_call]=[snr,time.time()]
                    if(("/A" in from_call) and ("{" in value) and ("}" in value)):
                        print("Got info")
                        now=time.time()
                        last_info=now
                        last_sent_pir=now
                        a_stations[from_call]=[snr,time.time()]
                        info=json.loads(value[value.find('{'):value.find('}')+1])
        except socket.timeout:
            n=n+1

thread1 = Thread(target=rx_thread, args=("RX Thread",))
thread1.start()

while True:
    time.sleep(5)
    now=time.time()
    if(info):
        print("I have the info I need: " + json.dumps(info))
    else:
        if(len(a_stations)>0):
            print("I do not have the info I need to generate a PIR. If I don't receive it in " + str(120-int(now-last_info)) + " seconds, I'm going to ask for it.")
        else:
            print("I do not have the info I need to generate a PIR, and I have nobody to ask for it.")
    if(len(a_stations)>0):
        print("My Aggregation Station is: " + list(a_stations.keys())[0].split('/')[0])
    else:
        print("I have no Aggregation Station to talk to.")
    if(info):
        print("I am sending my PIR in " + str(300-int(now-last_sent_pir)) + " seconds.")
    else:
        print("I cannot send my PIR.")
    if(ack):
        print("I got my last ACK back.")
    else:
        print("I did not get my last ACK back (yet).")
    print()
    if(not(info) and (now>=last_info+120) and (len(a_stations)>0)):
        last_info=now
        send_message(list(a_stations.keys())[0].split('/')[0] + " info?")
    if((info) and (now>=last_sent_pir+300) and (len(a_stations)>0)):
        last_sent_pir=now
        ack=False
        send_message("msg " + list(a_stations.keys())[0].split('/')[0] + " " + grid + ";PIR1=" + ['R','Y','G','U'][random.randint(0,3)])
