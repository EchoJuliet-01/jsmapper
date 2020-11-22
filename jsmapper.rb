#!/usr/bin/env ruby
# coding: utf-8

# AmRRON, EJ-01
# v1.0

require 'time'
require 'json'
require 'optimist'
require 'maidenhead'

# Set some defaults.
mycall=nil
verbose=false
dial_freq=0
bandwidth=999999999
start_time=Time.parse("1970/01/01 00:00:00").to_i
end_time=Time.now.to_i
in_file=Dir.home+"/.local/share/JS8Call/DIRECTED.TXT"

# These are the command line options.
opts=Optimist::options do
  opt :mycall, "My Call Sign", :type => :string
  opt :dial_freq, "Dial Frequency (in khz, defaults to all logged traffic)", :type => :string
  opt :bandwidth, "Bandwidth (in khz, defaults to 3khz)", :type => :string
  opt :start_time, "Start time/date (YYYY/MM/DD HH:MM:SS, system time zone)", :type => :string
  opt :end_time, "End time/date (YYYY/MM/DD HH:MM:SS, system time zone)", :type => :string
  opt :in_file, "JS8Call log file (defaults to ~/.local/share/JS8Call/DIRECTED.TXT)", :type => :string
  opt :verbose, "Spew verbose logging data"
end

# See if the user wants extra spew.
if opts[:verbose_given]
  verbose=true
end

# The call sign is mandatory.
if !opts[:mycall_given]
  puts "--mycall must be specified."
  exit
else
  mycall=opts[:mycall].upcase
end

# Get dial frequency.
if opts[:dial_freq_given]
  dial_freq=opts[:dial_freq].to_i
end

# Get bandwidth.
if opts[:bandwidth_given]
  bandwidth=opts[:bandwidth].to_i
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
if(dial_freq!=0)
  puts("Start Freq: #{dial_freq} khz")
  puts("Bandwidth: #{bandwidth} khz")
else
  puts("Will parse records at all frequencies.")
end
puts("Input File: #{in_file}")
puts()

# Scale up to the units the log file uses.
dial_freq*=1000
bandwidth*=1000

# Places to stash stuff. We're throwing a lot of potentially valuable
# info on the floor at this point. For example, we could easily build
# a map of reported SNR values between pairs of stations over time. We
# could also build connectivity maps, as we actually have quite a lot
# of information about who is successfully copying who, and the paths
# that relayed messages take through the network. In future versions,
# we should capture this data. If enough data were collected over time
# (along with propagation data), particularly if aggregated from many
# sources, it might be useful to build some real-world per-band
# predictive algorithms based on actual observed data, instead of just
# theory. The metadata would also be priceless for a building a
# compehensive picture of various groups and their memberships in the
# event of SHTF* (see below). It's all here in the raw data, we just
# have to use it instead of throwing it away.  Hey, if the bad guys
# can use big data and metadata, so can the good guys.
#
# * https://kieranhealy.org/blog/archives/2013/06/09/using-metadata-to-find-paul-revere/).
info=Hash.new()
status=Hash.new()
heard=Hash.new()
grids=Hash.new()

# Read the directed text file.
File.readlines(in_file).each do |line|
  # Split the line up into it's constituent parts (sure would be
  # cleaner to log in JSON, hint hint...).
  thing=line.split(" ",6)

  # Extract some useful stuff.
  date=thing[0]
  time=thing[1]
  freq=thing[2].to_f*1000000
  snr=thing[4]
  grid=nil
  lat=nil
  lon=nil

  # Iterate through each line of the file. Note that DIRECTED.TXT does
  # not contain transmissions, only complete, directed receptions,
  # though it's possible that the reception missed a frame. This is
  # represented by the "…" character. We throw those out, as we have
  # no way to meaningfully parse a line with missing data (without
  # AI). We also have to work around what looks like a bug in JS8Call,
  # where occasionally, a line will be missing the SNR entirely. This,
  # of course, throws off parsing for the whole line, so for now, we
  # just discard these lines. Might be able to do something more
  # useful with them in 2.0... We should probably also parse
  # ALL.TXT. It's horrific to piece together the fragmented lines, but
  # it might be worth at least pulling out the data your own station
  # transmitted, as that's the only place to find it.
  if(thing[5])
    if((!thing[5].include?("…"))&&(thing[5].include?("♢"))&&
       (freq.to_i>0)&&(date.include?('-'))&&(time.include?(':'))&&
       ((snr[0]=='+')||snr[0]=='-')&&(freq>=dial_freq)&&
       (freq<=dial_freq+bandwidth))

      # Grab timestamp.
      timestamp_t=Time.parse(date+" "+time+" GMT").to_i

      # Trim off the EOM marker, clean up the message content, split it
      # up into words, and store it in a reversed array so we can start
      # popping things off for analysis, one by one.
      stuff=thing[5].gsub('♢','').strip.split.reverse

      # Clear all the vars.
      from=nil
      to=nil
      from_relay=nil
      to_relay=nil

      # The from call will always be first.
      from=stuff.pop

      # Now it starts getting weird. JS8Call allows for spaces in the
      # call sign (dude, WTF?). Sometimes people separate out the "/P"
      # or "/M" with a space, so keep pulling stuff until you find the
      # ':'. If there are spaces, keep only the first bit; everything
      # else is trash (for our purposes). Once we find the trailing
      # ':', we're done.  Strip off the "/whatever" bits (if there are
      # any), and we're left with our from call. Unless the user did
      # something *REALLY* strange with his call sign, which case,
      # screw it, he doesn't get logged).  Much of this goes out the
      # window if it's a relay station. We'll deal with that below.
      crap=from
      # In theory, this could blow up if the payload is
      # mangled. Should probably add some logic for that here.
      while(!crap.include?(':'))
        crap=stuff.pop
      end
      from=(from.split('/'))[0].gsub(':','')
      heard[from]=timestamp_t

      # After the ':' word at the beginning, the next word is the to
      # call. It may or may not be the final to call; it could be the
      # intermediate relay. We'll figure that out in a minute.
      to=stuff.pop
      if(stuff[1]=="*DE*")
        from_relay=from
        heard[from_relay]=timestamp_t
        from=(stuff[0].gsub('>','').split('/'))[0]
        heard[from]=timestamp_t
        stuff=stuff[2..-1]
      end
      to=(to.gsub('>','').split('/'))[0]
      heard[to]=timestamp_t

      # Now grab the next word in the message payload. If it ends in
      # '>', it's the actual to call, and what we stored as the to
      # previously is actually a relay. If it has a '>' in the middle
      # of the word, then in theory, it's the actual to call munged
      # together with the first word of the payload because the luser
      # didn't leave a space in his message after the to call. We have
      # no reasonable way to disambiguate that from the first word of
      # the message not being a call but having an embedded '>', so
      # we'll assume the former, split the pieces, and push the bit of
      # text after the '>' back into the message. If there's no '>' at
      # all, then we grabbed the first word of the actual message
      # payload, so we'll push it back. It's possible there's no more
      # text at this point (ie, it's an empty message, though that
      # would be dumb).
      if(stuff.length>0)
        tmp=stuff.pop
        if(tmp[-1]=='>')
          to_relay=to
          heard[to_relay]=timestamp_t
          to=(tmp.gsub('>','').split('/'))[0]
          heard[to]=timestamp_t
        elsif(tmp.include?('>'))
          to_relay=to
          thing=tmp.split('>',2)
          to=thing[0].split('/')[0]
          heard[to]=timestamp_t
          stuff.push(thing[1])
        else
          stuff.push(tmp)
        end
        
        # In theory, we now know to, from, to_relay (if any), and
        # from_relay (if any). The rest of the message payload is our
        # actual message. The first word of that might or might not be
        # a command (MSG, HEARTBEAT, GRID?, or any one of a long list
        # of others. Check for the ones we care about, and if present,
        # store the data to put on the map. Could be ACK, AGN?,
        # @ALLCALL, APRS::SMSGTE (???), CMD, CQ, GRID, GRID?, HEARING,
        # HEARING?, HEARTBEAT, INFO, INFO?, MSG, NACK (???), SNR,
        # SNR?, STATUS, STATUS?, QUERY MSGS, QUERY MSG <num>, QUERY
        # <call>?
        if(stuff[-1]=='GRID')
          grid=stuff[-2]
        end
        if(stuff[-1]=='INFO')
          info[from]=stuff.reverse[1..-1].join(' ')
        end
        if(stuff[-1]=='STATUS')
          status[from]=stuff.reverse[1..-1].join(' ')
        end
        text=stuff.reverse.join(' ')
      else
        text=""
      end

      # Show what we've got if we're in verbose mode.
      puts("Time: #{Time.at(timestamp_t)}") if(verbose)
      puts("From: #{from}") if(verbose)
      if(from_relay)
        puts("From Relay: #{from_relay}") if(verbose)
      end
      puts("To: #{to}") if(verbose)
      if(to_relay)
        puts("To Relay: #{to_relay}") if(verbose)
      end
      puts("Freq: #{freq}") if(verbose)
      puts("SNR: #{snr}") if(verbose)
      if(grid)
        # Some jackass in the last exercise had a "," in their grid,
        # so weed that crap out.
        grids[from]=grid.gsub(',','')
        begin
          (lat,lon)=Maidenhead.to_latlon(grid)
          puts("Grid: #{grid}") if(verbose)
        rescue ArgumentError
          puts("Error: invalid grid") if(verbose)
        else
          puts("Lat: #{lat}") if(verbose)
          puts("Lon: #{lon}") if(verbose)
        end
      end
      if(info[from])
        puts("Info: #{info[from]}") if(verbose)
      end
      if(status[from])
        puts("Status: #{status[from]}") if(verbose)
      end
      puts("Text: #{text}") if(verbose)
      puts() if(verbose)
    end
  end
end

puts("The following stations never reported a grid:")
puts(heard.sort_by{|call,time| time}.reverse.map{|n| n[0]}.select{|n| n[0]!="@"}.join(", "))

index=0
File.open("amrron.csv", 'w') do |yacc|
  heard.sort_by{|call,time| time}.reverse.each do |n|
    if((n[0][0]!="@")&&(grids[n[0]]))
      begin
        loc=Maidenhead.to_latlon(grids[n[0]])
      rescue ArgumentError
        puts("Invalid grid square: #{n[0]}: #{grids[n[0]]}") if(verbose)
      else
        # Manipulate the latitude data until it meets the requirements
        # for an APRS packet.
        lat_d=loc[0].to_i
        if(lat_d<0); lat_d*=-1; ns="S"; else; ns="N"; end
        lat_d_s=lat_d.to_s
        if(lat_d_s.length<2); lat_d_s="0"+lat_d_s; end
        lat_m=(loc[0].abs-lat_d.abs)*60.0
        lat_m_s=lat_m.to_s
        if(lat_m<10); lat_m_s="0"+lat_m_s; end
        tmp=lat_m_s.split('.')
        if(tmp[1].length<2); lat_m_s=lat_m_s+"0"; end
        lat_m_s=lat_m_s[0..4]
        # Manipulate the longtude data until it meets the requirements
        # for an APRS packet.
        lon_d=loc[1].to_i
        if(lon_d<0); lon_d*=-1; ew="W"; else; ew="E"; end
        lon_d_s=lon_d.to_s
        if(lon_d_s.length<3); lon_d_s="0"+lon_d_s; end
        if(lon_d_s.length<3); lon_d_s="0"+lon_d_s; end
        lon_m=((loc[1].abs-lon_d.abs).abs)*60.0
        lon_m_s=lon_m.to_s
        if(lon_m<10); lon_m_s="0"+lon_m_s; end
        tmp=lon_m_s.split('.')
        if(tmp[1].length<2); lon_m_s=lon_m_s+"0"; end
        lon_m_s=lon_m_s[0..4]
        # For now, the symbol displayed is hard-coded (a palm tree on
        # a little desert island).
        sym_table="/"
        sym_code="i"
        # Clean up the data info.
        heard_time=Time.at(heard[n[0]]).to_s.split
        date=heard_time[0].split('-')
        timestamp=[date[2],['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date[1].to_i-1],date[0]].join('/')+" "+heard_time[1]
        # Write it all to the csv file.
        yacc.puts("#{timestamp},#{"Loc"+(index+=1).to_s}>NULL:=#{lat_d_s}#{lat_m_s}#{ns}#{sym_table}#{lon_d_s}#{lon_m_s}#{ew}#{sym_code} #{grids[n[0]]} #{info[n[0]].to_s}")
      end
    end
  end
end

