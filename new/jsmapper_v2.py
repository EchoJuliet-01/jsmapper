#!/usr/bin/env python3
# coding: utf-8

# AmRRON, EJ-01

import socket
import json
import time
import random
import cherrypy
import string
import os, os.path
from threading import Thread

# All of this will be user-supplied options in the future. For now,
# they're hard-coded.
js8_host='localhost'
js8_port=2442
grid=""
my_call=""
avg_pir_interval=300
avg_info_wait=300
max_age=3690

# Do some initializing.
info=False
as_stations={}
heard_stations={}
my_pirs={}
last_info=time.time()
last_sent_pir=last_info
ack=False
dial_freq=-1
offset_freq=-1
mode_speed=-1
cherrypy.config.update({'server.socket_port': 8000})
cherrypy.server.socket_host = '0.0.0.0'

# Testing only... TODO: Remove
as_stations['N0WAY']=[-7,time.time()-random.randint(0,3600)]
as_stations['N0BDY']=[-5,time.time()-random.randint(0,3600)]
as_stations['N0SHT']=[-17,time.time()-random.randint(0,3600)]
#info={"GRID":"10","PIR1":"R","PIR2":"R"}
heard_stations['AA0AA']=[random.randint(-18,10),time.time()-random.randint(0,3600),"DN11;PIR1=" + ['R','Y','G','U'][random.randint(0,3)]]
heard_stations['AA0BB']=[random.randint(-18,10),time.time()-random.randint(0,3600),"DM12;PIR1=" + ['R','Y','G','U'][random.randint(0,3)]]
heard_stations['AA0CC']=[random.randint(-18,10),time.time()-random.randint(0,3600),"DL13;PIR1=" + ['R','Y','G','U'][random.randint(0,3)]]
heard_stations['AA0DD']=[random.randint(-18,10),time.time()-random.randint(0,3600),"DK14;PIR1=" + ['R','Y','G','U'][random.randint(0,3)]]
heard_stations['AA0EE']=[random.randint(-18,10),time.time()-random.randint(0,3600),"DJ15;PIR1=" + ['R','Y','G','U'][random.randint(0,3)]]

# Randomize the intervals a bit so stations don't step on each other.
pir_interval=random.randint(int(avg_pir_interval*0.75),int(avg_pir_interval*1.25))
info_wait=random.randint(int(avg_info_wait*0.75),int(avg_info_wait*1.25))

# Open a socket to JS8Call.
s=socket.socket()
s.connect((js8_host,js8_port))
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

# Ask JS8Call for the current modulation speed.
def get_speed():
    global s
    s.sendall(bytes(json.dumps({'params': {}, 'type': 'MODE.GET_SPEED', 'value': ''})+"\r\n",'utf-8'))
    return

# Ask JS8Call for the current rig frequency.
def get_rig_freq():
    global s
    s.sendall(bytes(json.dumps({'params': {}, 'type': 'RIG.GET_FREQ', 'value': ''})+"\r\n",'utf-8'))
    return

# Ask JS8Call for the grid square as configured in the software.
def get_my_grid():
    global s
    s.sendall(bytes(json.dumps({'params': {}, 'type': 'STATION.GET_GRID', 'value': ''})+"\r\n",'utf-8'))
    return

# Ask JS8Call for my callsign as configured in the software.
def get_my_call():
    global s
    s.sendall(bytes(json.dumps({'params': {}, 'type': 'STATION.GET_CALLSIGN', 'value': ''})+"\r\n",'utf-8'))
    return

def web_thread(name):
    print("Starting " + name)
    print()
    conf = {
        '/': {
            'tools.sessions.on': True,
            'tools.staticdir.root': os.path.abspath(os.getcwd())
        },
        '/static': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': './public'
        }
    }
    cherrypy.quickstart(jsmapper_generator(), '/', conf)

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
    global grid
    global my_call
    global dial_freq
    global offset_freq
    global mode_speed
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
                if(stuff['type']=='MODE.SPEED'):
                    print(stuff)
                    mode_speed=int(stuff['params']['SPEED'])
                if(stuff['type']=='RIG.FREQ'):
                    print(stuff)
                    dial_freq=int(stuff['params']['DIAL'])/1000.0
                    offset_freq=int(stuff['params']['OFFSET'])
                if(stuff['type']=='STATION.GRID'):
                    print(stuff)
                    grid=stuff['value']
                if(stuff['type']=='STATION.CALLSIGN'):
                    print(stuff)
                    my_call=stuff['value']
                elif(stuff['type']=='RX.DIRECTED'):
                    print(stuff)
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
                            last_info=time.time()-(avg_info_wait/2)+random.randint(int(avg_info_wait*0.875),int(avg_info_wait*1.125))
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

def as_stations_html():
    global as_stations
    global max_age
    best=best_station(as_stations,max_age)
    string=""
    string=string+"<table border=1><tr><th>Call</th><th>SNR</th><th>Last Heard</th><th>Selected</th></tr>"
    for call in list(as_stations.keys()):
        if(best==call):
            string=string+"<tr><td>"+call+"</td><td>"+str(as_stations[call][0])+"</td><td>"+time.asctime(time.gmtime(as_stations[call][1]))+"</td><td><center>***</center></td></tr>"
        else:
            string=string+"<tr><td>"+call+"</td><td>"+str(as_stations[call][0])+"</td><td>"+time.asctime(time.gmtime(as_stations[call][1]))+"</td><td></td></tr>"
    string=string+"</table>"
    return(string)

def rgyu_to_word(n):
    if(n=="R"):
        return("Red")
    elif(n=="G"):
        return("Green")
    elif(n=="Y"):
        return("Yellow")
    else:
        return("Unknown")

def heard_stations_html():
    string=""
    if(info):
        string=string+"<table border=1><tr><th>Call</th><th>SNR</th><th>Last Heard</th>"
        for key in list(info.keys()):
            string=string+"<th>"+key+"</th>"
        string=string+"</tr>"
        for call in list(heard_stations.keys()):
            string=string+"<tr>"
            string=string+"<td>"+call+"</td><td>"+str(heard_stations[call][0])+"</td>"
            string=string+"<td>"+time.asctime(time.gmtime(heard_stations[call][1]))+"</td>"
            heard_data=heard_stations[call][2].split(';')[::-1]
            # TODO: trim each one
            if("GRID" in info):
                this_grid=heard_data.pop()
            data={}
            for item in heard_data:
                tmp=item.split('=')
                data[tmp[0]]=tmp[1]
            for key in list(info.keys()):
                if(key=="GRID"):
                    string=string+"<td>"+this_grid+"</td>"
                else:
                    if(key in data):
                        if(info[key]=="R"):
                            string=string+"<td>"+rgyu_to_word(data[key])+"</td>"
                        else:
                            string=string+"<td>"+data[key]+"</td>"
                    else:
                        string=string+"<td></td>"
            string=string+"</tr>"
        string=string+"</table>"
    else:
        string=string+"<table border=1><tr><th>Call</th><th>SNR</th><th>Last Heard</th><th>Data</th></tr>"
        for call in list(heard_stations.keys()):
            string=string+"<tr><td>"+call+"</td><td>"+str(heard_stations[call][0])+"</td><td>"+time.asctime(time.gmtime(heard_stations[call][1]))+"</td><td>"+heard_stations[call][2]+"</td></tr>"
        string=string+"</table>"
    return(string)

def not_negative(n):
    if(n>=0):
        return(n)
    else:
        return(0)

def info_html():
    if(info):
        string=""
        for key in list(info.keys()):
            if(key!="GRID"):
                if(key in my_pirs):
                    if(info[key]=="R"):
                        string=string+"<tr><td>"+key+"</td><td>"+rgyu_to_word(my_pirs[key])+"</td></tr>"
                    else:
                        string=string+"<tr><td>"+key+"</td><td>"+my_pirs[key]+"</td></tr>"
                else:
                    string=string+"<tr><td>"+key+"</td><td></td></tr>"
        return(string)
    else:
        return("<tr><td></td><td></td></tr>")

def speed_word(n):
    if(n>=0 and n<=4):
        return(["Normal", "Fast", "Turbo", "Invalid", "Slow"][n])
    else:
        return("Unknown")

def value_or_unk(n):
    if(n<0):
        return("Unknown")
    else:
        return(str(n))

def selected(a,b):
    if(a==b):
        return(" selected")
    else:
        return("")

def pir_form_html():
    if(info):
        string=""
        for key in list(info.keys()):
            if(key=="GRID"):
                string=string+"<tr><td>Grid</td><td>"+grid+"</td></tr>"
            else:
                if(key in my_pirs):
                    if(info[key]=="R"):
                        string=string+"<tr><td>"+key+"</td><td>"
                        string=string+"<select name=\""+key+"\">"
                        string=string+"<option value=\"G\""+selected(my_pirs(key)),"G"+">Green</option>"
                        string=string+"<option value=\"Y\""+selected(my_pirs(key)),"Y"+">Yellow</option>"
                        string=string+"<option value=\"R\""+selected(my_pirs(key)),"R"+">Red</option>"
                        string=string+"<option value=\"U\""+selected(my_pirs(key)),"U"+">Unknown</option>"
                        string=string+"</select>"
                        string=string+"</td></tr>"
                    else:
                        string=string+"<tr><td>"+key+"</td><td><input type=\"text\" value=\""+my_pirs[key]+"\" name=\""+key+"\" /></td></tr>"
                else:
                    if(info[key]=="R"):
                        string=string+"<tr><td>"+key+"</td><td>"
                        string=string+"<select name=\""+key+"\">"
                        string=string+"<option value=\"G\">Green</option>"
                        string=string+"<option value=\"Y\">Yellow</option>"
                        string=string+"<option value=\"R\">Red</option>"
                        string=string+"<option value=\"U\">Unknown</option>"
                        string=string+"</select>"
                        string=string+"</td></tr>"
                    else:
                        string=string+"<tr><td>"+key+"</td><td><input type=\"text\" name=\""+key+"\" /></td></tr>"
    return(string)

class jsmapper_generator(object):
    @cherrypy.expose
    def index(self, **stuff):
        global my_pirs
        if(len(stuff)>0):
            for key in stuff:
                my_pirs[key]=stuff[key]
        return """<html>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
            <meta http-equiv = "refresh" content = "5; url = /"/>
          </head>
          <body>
            <center>
              <img src="/static/images/amrron_small.png" alt="AmRRON" />
            </center>
            <br />
            <br />
            <p>My Info</p>
            <table border=1>
              <tr><td>Call</td><td>""" + my_call + """</td></tr>
              <tr><td>Grid</td><td>""" + grid + """</td></tr>
              <tr><td>Modulation Speed</td><td>""" + speed_word(mode_speed) + """</td></tr>
              <tr><td>Dial Freq</td><td>""" + value_or_unk(dial_freq) + """ khz</td></tr>
              <tr><td>Offset</td><td>""" + value_or_unk(offset_freq) + """ hz</td></tr>
              <tr><td>Transmit Freq</td><td>""" + value_or_unk(dial_freq+(offset_freq/1000)) + """ khz</td></tr>
              <tr><td></td><td></td></tr>
              <tr><td>Reporting Format</td><td>""" + json.dumps(info) + """</td></tr>
              <tr><td></td><td></td></tr>
              """ + info_html() + """
              <tr><td></td><td></td></tr>
              <tr><td>Sending in</td><td>""" + str(not_negative(pir_interval-int(time.time()-last_sent_pir))) + """ seconds</td></tr>
            </table>
            <br />
            <br />
            <table>
              <tr>
                <td>
                  <form method="get" action="setpir">
                    <input type="hidden" name="send" value="now">
                    <button style="background-color: #daad86;" type="submit">Set PIR Values</button>
                  </form>
                </td>
                <td>
                  <form method="get" action="sendpirs">
                    <input type="hidden" name="send" value="now">
                    <button style="background-color: #daad86;" type="submit">Send PIR Now</button>
                  </form>
                </td>
              </tr>
            </table>
            <br />
            <br />
            <p>Aggregation Stations Heard</p>
           """ + as_stations_html() + """
            <br />
            <br />
            <p>Reporting Stations Heard</p>
           """ + heard_stations_html() + """
            <br />
            <br />
           """ + time.asctime(time.gmtime(time.time())) + """
            <br />
            <br />
          </body>
        </html>"""

    @cherrypy.expose
    def sendpirs(self, send=False):
        global last_sent_pir
        global avg_pir_interval
        last_sent_pir=time.time()-(2*avg_pir_interval)
        return """<html>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
            <meta http-equiv = "refresh" content = "1; url = /"/>
          </head>
          <body>
          </body>
        </html>"""

    @cherrypy.expose
    def setpir(self, send=False):
        return """<html>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
          </head>
          <body>
            <center>
              <img src="/static/images/amrron_small.png" alt="AmRRON" />
            </center>
            <br />
            <br />
            <p>PIRs</p>
            <form method="get" action="index">
              <table border=1>
                """ + pir_form_html() + """
              </table>
              <button style="background-color: #daad86;" type="submit">Update/Set PIR Status</button>
            </form>
            <br />
            <br />
          </body>
        </html>"""

if __name__ == '__main__':
    # Start the RX thread.
    thread1 = Thread(target=rx_thread, args=("RX Thread",))
    thread1.start()
    thread2 = Thread(target=web_thread, args=("Web Server Thread",))
    thread2.start()
    print()
    # Now loop forever, watching the globals for status, and
    # responding appropriately. Also, give the user periodic updates
    # as to the internal status of the state machine.
    while True:
        # Fetch my grid from JS8Call each time through the loop, in
        # case the user updates it.
        get_my_grid()
        time.sleep(0.5)
        # Fetch my callsign from JS8Call each time through the loop,
        # in case the user updates it.
        get_my_call()
        time.sleep(0.5)
        # Fetch the current frequency from JS8Call each time through the loop.
        get_rig_freq()
        time.sleep(0.5)
        # Fetch the current modulation speed from JS8Call each time
        # through the loop.
        get_speed()
        time.sleep(0.5)
        # Check the world every five seconds. TODO: Consider making
        # this user-adjustable. Or at least move it to a constant at
        # the top of the code.
        time.sleep(3)
        # Just so everybody below is on the same page...
        now=time.time()
        # Pick the best (ie, highest SNR) Aggregation Station to talk
        # to (if any).
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
        # more than my timeout for him to broadcast his INFO, ask for
        # it.
        if(not(info) and (now>=last_info+info_wait) and (best)):
            # Update the timeout.
            last_info=now
            # Re-randomize the wait (a little bit).
            info_wait=random.randint(int(avg_info_wait*0.75),int(avg_info_wait*1.25))
            # Send the INFO request to JS8Call.
            print()
            print("Requesting INFO from " + best + "...")
            print()
            send_message(best + " info?")
        # If I have a valid Aggregation Station, periodically send my
        # PIR data to him.
        if((info) and (now>=last_sent_pir+pir_interval) and (best) and len(my_pirs)>0):
            # Update the timeout.
            last_sent_pir=now
            # Re-randomize the wait (a little bit).
            pir_interval=random.randint(int(avg_pir_interval*0.75),int(avg_pir_interval*1.25))
            # Note that I have an outstanding ACK I'm looking for.
            ack=False
            # Send the PIR to JS8Call (just a random value for now).
            string=""
            if("GRID" in info):
                string=string+grid+";"
            for key in list(info.keys()):
                if((key in my_pirs) and (key!="GRID")):
                    string=string+key+"="+my_pirs[key]+";"
            if(string[-1:]==";"):
                string=string[0:-1]
            print()
            print("Sending PIR to " + best + "...")
            print()
            send_message(best + " MSG " + string)

# https://docs.cherrypy.org/en/latest/tutorials.html#tutorials
