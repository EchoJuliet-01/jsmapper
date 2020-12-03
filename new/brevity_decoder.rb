#!/usr/bin/env ruby
# coding: utf-8

# AmRRON, EJ-01
# v1.0

require 'optimist'

thing="W1BB de W1AA B2 50 EOT"

# These are the command line options.
opts=Optimist::options do
  opt :message, "Message to decode", :type => :string
end

# The call sign is mandatory.
if !opts[:message_given]
  puts "--message must be specified."
  exit
else
  thing=opts[:message].upcase
end

# ("A".."Z").each { |l| (0..9).each { |n| puts l+n.to_s }}

brev=Hash.new
brev['A0']="QSX"
brev['A1']="QRM/QRN"
brev['A2']="QRO"
brev['A3']="QRU"
brev['A4']="QRV"
brev['A5']="QRX"
brev['A6']="QRZ"
brev['A7']="QSB"
brev['A8']="QRS"
brev['A9']="QST"
brev['B0']="Text/SMS"
brev['B1']="ARL"
brev['B2']="AP"
brev['B3']="Amcon"
brev['B4']="liaison"
brev['B5']="NCS"
brev['B6']="NWOTW"
brev['B7']="SigCen"
brev['B8']="SITREP"
brev['B9']="STATREP"
brev['C0']="Red/High/Dangerous"
brev['C1']="Location"
brev['C2']="Commerical Power"
brev['C3']="Water"
brev['C4']="Sanitation"
brev['C5']="Medical"
brev['C6']="Grid Communications"
brev['C7']="Transportation"
brev['C8']="Green/Normal/All Well"
brev['C9']="Yellow/Moderate/Cautious"
brev['D0']="Civil Conditions"
brev['D1']="Temperature"
brev['D2']="Wind"
brev['D3']="Snow/Ice"
brev['D4']="Rain/Hail"
brev['D5']="Hurricane/Tornado"
brev['D6']="Heat/Drought"
brev['D7']="Operator/Family Condition"
brev['D8']="City/County Conditions"
brev['D9']="Political Conditions"
brev['E0']="Antenna"
brev['E1']="Isa 40:31"
brev['E2']="back"
brev['E3']="cook/cooking"
brev['E4']="for"
brev['E5']="if"
brev['E6']="most"
brev['E7']="plan"
brev['E8']="so"
brev['E9']="unrest"
brev['F0']="Radio"
brev['F1']="abort/cancel/stop"
brev['F2']="backbone"
brev['F3']="current"
brev['F4']="found"
brev['F5']="I/me"
brev['F6']="motor"
brev['F7']="power"
brev['F8']="solar panel"
brev['F9']="until"
brev['G0']="Station"
brev['G1']="about/approximate"
brev['G2']="band/frequency"
brev['G3']="day/days/date"
brev['G4']="friends"
brev['G5']="incident"
brev['G6']="must"
brev['G7']="PPE"
brev['G8']="some"
brev['G9']="up/+"
brev['H0']="ARIM/gARIM"
brev['H1']="activate/activation"
brev['H2']="battery"
brev['H3']="dead"
brev['H4']="from"
brev['H5']="info"
brev['H6']="my/mine"
brev['H7']="pray/praying"
brev['H8']="stable"
brev['H9']="use"
brev['I0']="FLAMP"
brev['I1']="advise"
brev['I2']="be"
brev['I3']="deliver/delivery"
brev['I4']="funds/$"
brev['I5']="injury/injured"
brev['I6']="near"
brev['I7']="propane"
brev['I8']="supply/provide"
brev['I9']="US National Grid"
brev['J0']="FLDIGI"
brev['J1']="after/later"
brev['J2']="be alert/danger"
brev['J3']="diesel"
brev['J4']="gasoline"
brev['J5']="in/to/into"
brev['J6']="need/needs"
brev['J7']="range supplies"
brev['J8']="survey"
brev['J9']="voice"
brev['K0']="FLMSG"
brev['K1']="again/Re-"
brev['K2']="because"
brev['K3']="digital"
brev['K4']="generator"
brev['K5']="is/are"
brev['K6']="negotiate/trade"
brev['K7']="rationing"
brev['K8']="take"
brev['K9']="wait/waiting"
brev['L0']="JS8CALL"
brev['L1']="all"
brev['L2']="bedding"
brev['L3']="disease/infection"
brev['L4']="get/heard/RX"
brev['L5']="it/it's"
brev['L6']="net"
brev['L7']="refrigerator/refrigerated"
brev['L8']="tarp/tent"
brev['L9']="want"
brev['M0']="Contestia 4-250"
brev['M1']="all is well"
brev['M2']="before/earlier"
brev['M3']="distress/emergency"
brev['M4']="give/gave"
brev['M5']="know"
brev['M6']="no/not/negative"
brev['M7']="relay"
brev['M8']="than/then"
brev['M9']="water"
brev['N0']="CW"
brev['N1']="allow"
brev['N2']="better/improve"
brev['N3']="do"
brev['N4']="go"
brev['N5']="left/remain"
brev['N6']="now"
brev['N7']="report"
brev['N8']="that"
brev['N9']="well"
brev['O0']="FSQ"
brev['O1']="also"
brev['O2']="but"
brev['O3']="down/-"
brev['O4']="good"
brev['O5']="like"
brev['O6']="of"
brev['O7']="request"
brev['O8']="there/their"
brev['O9']="we/us/ours"
brev['P0']="MFSK"
brev['P1']="and/&"
brev['P2']="by/via/way"
brev['P3']="electrical equipment"
brev['P4']="group/team"
brev['P5']="location/position"
brev['P6']="oil"
brev['P7']="respond/response"
brev['P8']="these/those"
brev['P9']="what"
brev['Q0']="20m Digital 14110 USB"
brev['Q1']="any"
brev['Q2']="can/could"
brev['Q3']="eMail"
brev['Q4']="has/have"
brev['Q5']="look/survey"
brev['Q6']="on"
brev['Q7']="rest"
brev['Q8']="they/them"
brev['Q9']="when"
brev['R0']="20m Voice 14342 USB"
brev['R1']="area/region"
brev['R2']="change"
brev['R3']="en-route"
brev['R4']="headquarters"
brev['R5']="loss/lost"
brev['R6']="only"
brev['R7']="restrictions"
brev['R8']="think"
brev['R9']="which"
brev['S0']="30m Digital 10141.5 USB"
brev['S1']="arrive/arrived/arriving"
brev['S2']="child/children"
brev['S3']="evacuate/evacuation"
brev['S4']="he/him/male"
brev['S5']="Maidenhead Grid"
brev['S6']="operate/operating"
brev['S7']="route"
brev['S8']="this"
brev['S9']="who"
brev['T0']="40m Digital 7110 USB"
brev['T1']="as"
brev['T2']="come"
brev['T3']="extraction"
brev['T4']="help"
brev['T5']="make"
brev['T6']="or"
brev['T7']="say/said"
brev['T8']="time"
brev['T9']="will"
brev['U0']="40m Voice 7242 LSB"
brev['U1']="ASAP/urgent"
brev['U2']="comms"
brev['U3']="file"
brev['U4']="holding/pending"
brev['U5']="meet/assemble/QSY"
brev['U6']="other"
brev['U7']="security"
brev['U8']="today"
brev['U9']="with"
brev['V0']="80m Digital 3588 USB"
brev['V1']="at/@"
brev['V2']="compromise/compromised"
brev['V3']="filter"
brev['V4']="home/QTH"
brev['V5']="message"
brev['V6']="out/remove"
brev['V7']="see/seen"
brev['V8']="tools"
brev['V9']="worse/degrade"
brev['W0']="80m Voice 3818 LSB"
brev['W1']="authenticate"
brev['W2']="condition/conditions"
brev['W3']="first aid/medical"
brev['W4']="hours"
brev['W5']="miles"
brev['W6']="over"
brev['W7']="send/TX"
brev['W8']="total"
brev['W9']="would"
brev['X0']="KHz"
brev['X1']="axe/chainsaw"
brev['X2']="constant/steady"
brev['X3']="fix/repair"
brev['X4']="housing/shelter"
brev['X5']="minutes"
brev['X6']="part/partial"
brev['X7']="she/her/female"
brev['X8']="travel"
brev['X9']="yes/confirm/QSL"
brev['Y0']="VHF/UHF"
brev['Y1']="baby"
brev['Y2']="contact"
brev['Y3']="food"
brev['Y4']="how"
brev['Y5']="mobile/portable"
brev['Y6']="people"
brev['Y7']="shelf-stable"
brev['Y8']="unknown"
brev['Y9']="you/your"
brev['Z0']="0"
brev['Z1']="1"
brev['Z2']="2"
brev['Z3']="3"
brev['Z4']="4"
brev['Z5']="5"
brev['Z6']="6"
brev['Z7']="7"
brev['Z8']="8"
brev['Z9']="9"

ap=Hash.new
ap['00']="I need ___. Please contact me directly if you can assist."
ap['01']="I can supply ___. Please contact me directly if you have a need."
ap['02']="Reports of ___ shortages at this location."
ap['03']="Spare"
ap['04']="Spare"
ap['05']="Spare"
ap['06']="Spare"
ap['07']="Spare"
ap['08']="Spare"
ap['09']="Spare"
ap['10']="Shelter-in-place orders in effect at this location."
ap['11']="Desk-to-dawn curfew in effect at this location."
ap['12']="National Guard deployed at this location."
ap['13']="Spare"
ap['14']="Spare"
ap['15']="Spare"
ap['16']="Spare"
ap['17']="Spare"
ap['18']="Spare"
ap['19']="Spare"
ap['20']="Need housing for ___ displaced persons."
ap['21']="Need clothing for ___ in size ___."
ap['22']="Contagion rampant at this location - quarantine orders in effect."
ap['23']="Spare"
ap['24']="Spare"
ap['25']="Spare"
ap['26']="Spare"
ap['27']="Spare"
ap['28']="Spare"
ap['29']="Spare"
ap['30']="Severe weather at this location - travel is hazardous."
ap['31']="All routes ___ of this location are restricted."
ap['32']="Rioting/looting occurring at this location."
ap['33']="Spare"
ap['34']="Spare"
ap['35']="Spare"
ap['36']="Spare"
ap['37']="Spare"
ap['38']="Spare"
ap['39']="Spare"
ap['40']="This frequency is being monitored."
ap['41']="This is a persistent net."
ap['42']="This net will resume at ___ Z."
ap['43']="This net will QSY to ___."
ap['44']="Who is the NCS for this net?"
ap['45']="This station is NCS for this net."
ap['46']="Please relay."
ap['47']="Please re-transmit file ___."
ap['48']="Local cell/landline telephone service is ___."
ap['49']="Local broadcast TV/radio is ___."
ap['50']="Shelter(ing) in place."
ap['51']="Traveling on foot."
ap['52']="Traveling by vehicle."
ap['53']="Vehicle breakdown."
ap['54']="Leaving today."
ap['55']="Leaving tomorrow."
ap['56']="Meet at location ___."
ap['57']="Where do you suggest we go?"
ap['58']="Spare"
ap['59']="Spare"

arl=Hash.new
arl['01']="Everyone safe here. Please don't worry."
arl['04']="Only slight property damage here. Don't be concerned about disaster reports."
arl['05']="Am moving to a new location. Send no further mail or communication. Will inform you of new address when relocated."
arl['06']="Will contact you as soon as possible."
arl['11']="Establish amateur radio emergency communications with ___ on ___ Mhz."
arl['12']="Anxious to hear from you. No word in some time. Please contact me ASAP."
arl['14']="Situation here becoming critical. Losses and damage from ___ increasing."
arl['15']="Please advise your condition and what help is needed."
arl['16']="Property damage very severe in this area."
arl['18']="Please contact me as soon as possible at ___."
arl['19']="Request health and welfare report on ___."
arl['20']="Temporarily stranded. Will need some assistance. Please contact me at ___."
arl['21']="Search/Rescue assistance needed by local authorities here. Advise availability."
arl['22']="Need accurate information on the extent and type of conditions now existing at your location. Please furnish this information and reply."
arl['23']="Report at once the accessibility and best way to reach your location."
arl['24']="Evacuation of residents from this area urgently needed. Advise plans for help."
arl['25']="Furish as soon as possible the weather conditions at your location."
arl['64']="Arrived safely at ___."
arl['65']="Arriving on ___. Please arrange to meet me there."

stuff=thing.split
ap_mode=false
arl_mode=false
message=""

stuff.each do |n|
  if(brev.key?(n))
    if(n=="B2")
      ap_mode=true
    elsif(n=="B1")
      arl_mode=true
    else
      message=message+brev[n]+" "
    end
  elsif(arl_mode)
    arl_mode=false
    message=message+arl[n]+" "
  elsif(ap_mode)
    ap_mode=false
    message=message+ap[n]+" "
  else
    message=message+n+" "
  end
end

puts(message)
