#!/usr/bin/python3.8
# coding: utf-8

# AmRRON, EJ-01

import socket
import json
import time
import random
from threading import Thread

# All of this will be user-supplied options in the future. For now,
# they're hard-coded.
host='localhost'
port=2442
grid="DM79"
my_call="N0DUH"
avg_pir_interval=300
avg_info_wait=300
max_age=1890

# Do some initializing.
info=False
as_stations={}
last_info=time.time()
last_sent_pir=last_info
ack=False

# Randomize the intervals a bit so stations don't step on each other.
pir_interval=random.randint(int(avg_pir_interval*0.75),int(avg_pir_interval*1.25))
info_wait=random.randint(int(avg_info_wait*0.75),int(avg_info_wait*1.25))

# Open a socket to JS8Call.
s=socket.socket()
s.connect((host,port))
s.settimeout(1)

# Return the callsign of the station with the best SNR, but heard
# within the alotted number of seconds (so we're not trying to talk to
# an old station we might have last heard three days ago).
def best_station(stations,max_age):
    if(len(as_stations)>0):
        now=time.time()
        best_call=False
        best_snr=-99999
        for key in list(stations.keys()):
            if((stations[key][0]>best_snr) and (now-stations[key][1]<=max_age)):
                best_call=key
                best_snr=stations[key][0]
        return(best_call)
    else:
        return(False)

# Send a generic JS8Call message. This doesn't cover all the possible
# message types by any stretch, but it's all you need for
# non-specialized stuff.
def send_message(message):
    global s
    s.sendall(bytes(json.dumps({'params': {}, 'type': 'TX.SEND_MESSAGE', 'value': message})+"\r\n",'utf-8'))
    return

# Due to the way JS8Call sends data to an API client (ie, it just
# sends random JSON data whenever it pleases), we'll receive all
# messages in a thread so it'll all work in the background.
def rx_thread(name):
    # TODO: Reduce the number of globals. Add locks for the ones we
    # really need to keep.
    global info
    global s
    global as_stations
    global last_info
    global last_sent_pir
    global ack
    print("Starting " + name)
    print()
    n=0
    # Run forever.
    while True:
        try:
            # The 1024 byte limitation will be an issue if you try to
            # re-use this code to do wild things, like show all
            # received text. But for simple tx/rx of short messages,
            # it's fine. TODO: if you're going to do fancy stuff, this
            # needs work.
            stuff=json.loads(s.recv(1024).strip())
            # We only care about one very specific type of message
            # from JS8Call: Directed Messages. We discard all other
            # traffic.
            if 'type' in stuff:
                if(stuff['type']=='RX.DIRECTED'):
                    # Extract everything interesting from the received
                    # message. We don't use all of it (right now), but
                    # it's easy enough to grab, so we do.
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
                    # Show the message we received to STDOUT.
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
                    # We're specifically looking for ACK
                    # messages. Weed out the ones directed to my own
                    # callsign. Don't worry about where they came from
                    # for now. TODO: Worry about where they came from.
                    tmp=value.split()
                    if(len(tmp)>=4):
                        if((tmp[1]==my_call) and (tmp[2]=="ACK")):
                            ack=True
                    # If the station has a "/A" suffix, it's a
                    # Aggregation Station. Record it's callsign, SNR,
                    # and the current timestamp so we know who to send
                    # data to later.
                    if("/A" in from_call):
                        # Wait half the specified time before we bug
                        # the AS if this is the first AS we've seen.
                        if(len(as_stations)==0):
                            last_info=time.time()+(avg_info_wait/2)
                        as_stations[(from_call.split('/')[0]).strip()]=[snr,time.time()]
                    # If there's (maybe) JSON data in the message, try
                    # to extract it. Failed extractions are caught by
                    # the except below. TODO: Discard messages
                    # containing "..." and/or missing the EOM marker.
                    if(("/A" in from_call) and ("{" in value) and ("}" in value)):
                        print("Got info")
                        now=time.time()
                        last_info=now
                        last_sent_pir=now
                        if(len(as_stations)==0):
                            last_info=time.time()+(avg_info_wait/2)
                        as_stations[(from_call.split('/')[0]).strip()]=[snr,time.time()]
                        # Parse the received JSON.
                        info=json.loads(value[value.find('{'):value.find('}')+1])
        # Catch exceptions. TODO: We need to be WAY more specific
        # about this. First, the socket.timeout (happens once per
        # second) should be handled specifically. Second, JSON parsing
        # failures should have their own special case, as well. Then
        # maybe a catch-all for everything else.
        except:
            # For now, just count the errors. No reason. Just because.
            n=n+1

# Start the RX thread.
thread1 = Thread(target=rx_thread, args=("RX Thread",))
thread1.start()

# Now loop forever, watching the globals for status, and responding
# appropriately. Also, give the user periodic updates as to the
# internal status of the state machine.
while True:
    # Check the world every five seconds. TODO: Consider making this
    # user-adjustable. Or at least move it to a constant at the top of
    # the code.
    time.sleep(5)
    # Just so everybody below is on the same page...
    now=time.time()
    # Pick the best (ie, highest SNR) Aggregation Station to talk to
    # (if any).
    best=best_station(as_stations,max_age)
    # Give an update to the user.
    if(info):
        print("I have the info I need: " + json.dumps(info))
    else:
        if(len(as_stations)>0):
            print("I do not have the info I need to generate a PIR. If I don't receive it in " + str(info_wait-int(now-last_info)) + " seconds, I'm going to ask for it.")
        else:
            print("I do not have the info I need to generate a PIR, and I have nobody to ask for it.")
    if(best):
        print("My Aggregation Station is: " + best)
    else:
        print("I have no Aggregation Station to talk to.")
    if(info):
        print("I am sending my PIR in " + str(pir_interval-int(now-last_sent_pir)) + " seconds.")
    else:
        print("I cannot send my PIR.")
    if(ack):
        print("I got my last ACK back.")
    else:
        print("I did not get my last ACK back (yet).")
    print()
    # If I have an Aggregation Station to talk to, and I've waited
    # more than my timeout for him to broadcast his INFO, ask for it.
    if(not(info) and (now>=last_info+info_wait) and (best)):
        # Update the timeout.
        last_info=now
        # Re-randomize the wait (a little bit).
        info_wait=random.randint(int(avg_info_wait*0.75),int(avg_info_wait*1.25))
        # Send the INFO request to JS8Call.
        send_message(best + " info?")
    # If I have a valid Aggregation Station, periodically send my PIR
    # data to him.
    if((info) and (now>=last_sent_pir+pir_interval) and (best)):
        # Update the timeout.
        last_sent_pir=now
        # Re-randomize the wait (a little bit).
        pir_interval=random.randint(int(avg_pir_interval*0.75),int(avg_pir_interval*1.25))
        # Note that I have an outstanding ACK I'm looking for.
        ack=False
        # Send the PIR to JS8Call (just a random value for now).
        send_message("msg " + best + " " + grid + ";PIR1=" + ['R','Y','G','U'][random.randint(0,3)])
