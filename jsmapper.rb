#!/usr/bin/env ruby
# coding: utf-8

# AmRRON, EJ-01

require 'time'
require 'json'
require 'optimist'
require 'maidenhead'

# Set some defaults.
mycall=nil
@dial_freq=0
@bandwidth=999999999
start_time=Time.parse("1970/01/01 00:00:00").to_i
end_time=Time.now.to_i
in_file=Dir.home+"/.local/share/JS8Call/DIRECTED.TXT"

red_code=['/',':'] # Fire
yel_code=['\\','U'] # Sun
grn_code=['\\','W'] # Green Circle
unk_code=['\\','0'] # Grey Circle

# These are the command line options.
opts=Optimist::options do
  opt :mycall, "My Call Sign", :type => :string
  opt :dial_freq, "Dial Frequency (in khz, defaults to all logged traffic)", :type => :string
  opt :bandwidth, "Bandwidth (in khz, defaults to 3khz)", :type => :string
  opt :start_time, "Start time/date (YYYY/MM/DD HH:MM:SS, system time zone)", :type => :string
  opt :end_time, "End time/date (YYYY/MM/DD HH:MM:SS, system time zone)", :type => :string
  opt :in_file, "JS8Call log file (defaults to ~/.local/share/JS8Call/DIRECTED.TXT)", :type => :string
  opt :debug, "Spew debug data"
end

# Debug?
@debug=false
if opts[:debug_given]
  @debug=true
end

# The call sign is mandatory.
if !opts[:mycall_given]
#  puts "--mycall must be specified."
#  exit
else
  mycall=opts[:mycall].upcase
end

# Get dial frequency.
if opts[:dial_freq_given]
  @dial_freq=opts[:dial_freq].to_i
end

# Get bandwidth.
if opts[:bandwidth_given]
  @bandwidth=opts[:bandwidth].to_i
else
  if opts[:dial_freq_given]
    bandwidth=3
  end
end

# Start time.
if opts[:start_time_given]
  start_time=Time.parse(opts[:start_time]).to_i
end

# End time.
if opts[:end_time_given]
  end_time=Time.parse(opts[:end_time]).to_i
end

# Get input file.
if opts[:in_file_given]
  in_file=opts[:in_file]
end

puts("My Call: #{mycall}")
if(start_time!=Time.parse("1970/01/01 00:00:00").to_i)
  puts("Start Time: #{Time.at(start_time).to_s}")
  puts("End Time: #{Time.at(end_time).to_s}")
else
  puts("Will parse records with all timestamps.")
end
if(@dial_freq!=0)
  puts("Start Freq: #{@dial_freq} khz")
  puts("Bandwidth: #{@bandwidth} khz")
else
  puts("Will parse records at all frequencies.")
end
puts("Input File: #{in_file}")
puts()

# Scale up to the units the log file uses.
@dial_freq*=1000
@bandwidth*=1000

# This class holds a message.
class Message
  attr_accessor :timestamp, :freq, :from, :to, :from_relay, :to_relay, :type, :message, :ftx

  def initialize(timestamp, freq, from, to, from_relay, to_relay, type, message, ftx)
    @timestamp = timestamp
    @freq = freq
    @from = from
    @to = to
    @from_relay = from_relay
    @to_relay = to_relay
    @type = type
    @message = message
    @ftx = ftx
  end

  def to_s
    "Time: #{Time.at(@timestamp).to_s}\nFreq: #{@freq}\nFrom: #{@from}\nTo: #{@to}\nQuery: #{self.query}\nGroup: #{self.group}\nType: #{@type}\nMessage: #{@message}\nFTX: #{@ftx}\nGrid: #{@ftx['grid']}\nLocation: #{self.lat_lon}"
  end

  def lat_lon
    if(ftx.key?('grid'))
      begin
        return(Maidenhead.to_latlon(ftx['grid']))
      rescue ArgumentError
        return(nil)
      end
    else
      return(nil)
    end
  end

  def aprs_lat
    tmp=self.lat_lon
    if(tmp)
      lat=tmp[0]
      lat_deg=lat.to_i
      lat_min=((lat.abs-lat.abs.to_i)*60.0).abs
      lat_deg_s=(lat_deg.abs).to_s
      if(lat_deg<10); lat_deg_s="0"+lat_deg_s; end
      lat_min_s=lat_min.to_s
      if(lat_min<10); lat_min_s="0"+lat_min_s; end
      lat_s=(lat_deg_s+lat_min_s+"0000")[0..6]
      if(lat_deg<0); lat_s=lat_s+"S"; else lat_s=lat_s+"N"; end
      return(lat_s)
    else
      return(false)
    end
  end
  
  def aprs_lon
    tmp=self.lat_lon
    if(tmp)
      lon=tmp[1]
      lon_deg=lon.to_i
      lon_min=((lon.abs-lon.abs.to_i)*60.0).abs
      lon_deg_s=(lon_deg.abs).to_s
      if(lon_deg.abs<10); lon_deg_s="0"+lon_deg_s; end
      if(lon_deg.abs<100); lon_deg_s="0"+lon_deg_s; end
      lon_min_s=lon_min.to_s
      if(lon_min<10); lon_min_s="0"+lon_min_s; end
      lon_s=(lon_deg_s+lon_min_s+"0000")[0..7]
      if(lon_deg<0); lon_s=lon_s+"W"; else lon_s=lon_s+"E"; end
      return(lon_s)
    else
      return(false)
    end
  end
  
  def group
    if(@to[0..1]=='@')
      return(true)
    else
      return(false)
    end
  end

  def query
    if(@type[-1..-1]=='?')
      return(true)
    else
      return(false)
    end
  end
end

def extract(message)
  # Split the message up into it's constituent parts (sure would be
  # cleaner to log in JSON, hint hint...).
  thing=message.split(" ",6)

  # Extract some useful stuff.
  date=thing[0]
  time=thing[1]
  freq=thing[2].to_f*1000000
  snr=thing[4]
  payload=thing[5]

  # Note that DIRECTED.TXT does not contain transmissions, only
  # complete, directed receptions, though it's possible that the
  # reception missed a frame. This is represented by the "…"
  # character. We throw those out, as we have no way to meaningfully
  # parse a line with missing data (without AI). We also have to work
  # around what looks like a bug in JS8Call, where occasionally, a
  # line will be missing the SNR entirely. This, of course, throws off
  # parsing for the whole line, so for now, we just discard these
  # lines. Might be able to do something more useful with them in
  # 2.0... We should probably also parse ALL.TXT. It's horrific to
  # piece together the fragmented lines, but it might be worth at
  # least pulling out the data your own station transmitted, as that's
  # the only place to find it.
  if(payload)
    if((!payload.include?("…")) and 
       (freq.to_i>0) and (date.include?('-')) and (time.include?(':')) and 
       ((snr[0]=='+')||snr[0]=='-') and (freq>=@dial_freq) and 
       (freq<=@dial_freq+@bandwidth))
      
      # Grab timestamp.
      timestamp_t=Time.parse(date+" "+time+" GMT").to_i
      
      # Trim off the EOM marker, clean up the message content, split
      # it up into words, and store it in a reversed array so we can
      # start popping things off for analysis, one by one.
      flag=true
      # Don't choke on bogus UTF-8, just skip it.
      begin
        stuff=payload.gsub('♢','').strip.split.reverse
      rescue ArgumentError
        flag=false
      end
      
      if(flag)
        # Clear all the vars.
        from=nil
        to=nil
        from_relay=nil
        to_relay=nil
        
        # The from call will always be first.
        from=stuff.pop
        
        # Now it starts getting weird. JS8Call allows for spaces in
        # the call sign (dude, WTF?). Sometimes people separate out
        # the "/P" or "/M" with a space, so keep pulling stuff until
        # you find the ':'. If there are spaces, keep only the first
        # bit; everything else is trash (for our purposes). Once we
        # find the trailing ':', we're done.  Strip off the
        # "/whatever" bits (if there are any), and we're left with our
        # from call. Unless the user did something *REALLY* strange
        # with his call sign, which case, screw it, he doesn't get
        # logged).  Much of this goes out the window if it's a relay
        # station. We'll deal with that below.
        crap=from
        # In theory, this could blow up if the payload is
        # mangled. Should probably add some logic for that here.
        while(!crap.include?(':'))
          crap=stuff.pop
        end
        from=(from.split('/'))[0].gsub(':','')
        
        # After the ':' word at the beginning, the next word is the to
        # call. It may or may not be the final to call; it could be
        # the intermediate relay. We'll figure that out in a minute.
        to=stuff.pop
        if(stuff[1]=="*DE*")
          from_relay=from
          from=(stuff[0].gsub('>','').split('/'))[0]
          stuff=stuff[2..-1]
        end
        to=(to.gsub('>','').split('/'))[0]
        
        # Now grab the next word in the message payload. If it ends in
        # '>', it's the actual to call, and what we stored as the to
        # previously is actually a relay. If it has a '>' in the
        # middle of the word, then in theory, it's the actual to call
        # munged together with the first word of the payload because
        # the luser didn't leave a space in his message after the to
        # call. We have no reasonable way to disambiguate that from
        # the first word of the message not being a call but having an
        # embedded '>', so we'll assume the former, split the pieces,
        # and push the bit of text after the '>' back into the
        # message. If there's no '>' at all, then we grabbed the first
        # word of the actual message payload, so we'll push it
        # back. It's possible there's no more text at this point (ie,
        # it's an empty message, though that would be dumb).
        if(stuff.length>0)
          tmp=stuff.pop
          if(tmp[-1]=='>')
            to_relay=to
            to=(tmp.gsub('>','').split('/'))[0]
          elsif(tmp.include?('>'))
            to_relay=to
            thing=tmp.split('>',2)
            to=thing[0].split('/')[0]
            stuff.push(thing[1])
          else
            stuff.push(tmp)
          end
        end
        group=false
        if(to[0]=='@')
          group=true
        end
        type=stuff[-1]
        if(!["ACK", "AGN?", "CMD", "CQ", "GRID", "GRID?", "HEARING",
             "HEARING?", "HEARTBEAT", "INFO", "INFO?", "MSG", "SNR",
             "SNR?", "STATUS", "STATUS?", "QUERY MSGS", "APRS::SMSGTE",
             "NACK", "QUERY MSG", "QUERY"].member?(type) and type[0]!='@')
          type="TEXT"
        end
        ftx=Hash.new
        if((stuff[-1]=="MSG") and (stuff[-2]=="INFO"))
          crap=stuff.pop
          crap=stuff.pop
          message=(stuff.reverse.join(' ')).split(';')
          ftx['grid']=message[0].strip
        end
        if(stuff[-1]=="INFO")
          crap=stuff.pop
          message=(stuff.reverse.join(' ')).split(';')
          ftx['grid']=message[0].strip
        end
        if(message.class==Array)
          p message if @debug
          message[1..-1].each do |n| 
            item=n.split('=')
            ftx[item[0].strip.upcase]=item[1].strip.upcase
          end
          if(ftx.key?('grid') and (ftx.key?('PIR1') or ftx.key?('PRI1')))
            type="FTX"
          end
          return(Message.new(timestamp_t,freq,from,to,from_relay,to_relay,type,stuff.reverse,ftx))
        end
      end
    end
  end
end

# Read and process the DIRECTED.TXT file.
msgs=Array.new
File.readlines(in_file).each do |line|
  msg=extract(line)
  if(msg)
    msgs.push(msg)
  end
end

# Now let's write the output file.
index=0
File.open("amrron.csv", 'w') do |yacc|
  msgs.select {|m| m.type=="FTX"}.each do |message| 
    callsign=message.from
    loc=message.lat_lon

    if((message.ftx["PIR1"]=="G") or (message.ftx["PRI1"]=="G"))
      sym_table=grn_code[0]
      sym_code=grn_code[1]
    elsif((message.ftx["PIR1"]=="Y") or (message.ftx["PRI1"]=="Y"))
      sym_table=yel_code[0]
      sym_code=yel_code[1]
    elsif((message.ftx["PIR1"]=="R") or (message.ftx["PRI1"]=="R"))
      sym_table=red_code[0]
      sym_code=red_code[1]
    else
      sym_table=unk_code[0]
      sym_code=unk_code[1]
    end

    # Clean up the data info.
    heard_time=Time.at(message.timestamp).to_s.split
    date=heard_time[0].split('-')
    timestamp=[date[2],['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date[1].to_i-1],date[0]].join('/')+" "+heard_time[1]
    # Write it all to the csv file.
    lat=message.aprs_lat
    lon=message.aprs_lon
    if(lat and lon)
      yacc.puts("#{timestamp},#{"X0"+callsign[-2..-1]}>NULL:=#{lat}#{sym_table}#{lon}#{sym_code} #{message.ftx['grid']} #{message.message.join}")
    end
  end
end
