#!/usr/bin/env ruby
# coding: utf-8

# AmRRON, EJ-01
# v1.0

require 'optimist'
require 'csv'
require 'pry_debug'

in_file="/home/jfrancis/.config/JS8Call.ini" # xxx

# These are the command line options.
opts=Optimist::options do
  opt :in_file, "JS8Call log file (defaults to /home/pi/.local/share/JS8Call/DIRECTED.TXT)", :type => :string
end

# Get input file.
if opts[:in_file_given]
  in_file=opts[:in_file]
end

sections=Hash.new
section_list=Array.new
current_section=nil

File.readlines(in_file).each do |line|
  line.chomp!
  if(line.match(/^\[.*\]$/))
    section_list.push(line)
    sections[line]=Hash.new
    current_section=line
  else
    stuff=line.split('=',2)
    if(stuff.length==2)
      sections[current_section][stuff[0]]=stuff[1]
    end
  end
end

call=sections['[Configuration]']["MyCall"]
spot=sections['[Common]']["UploadSpots"]
aprs_spot=sections['[Configuration]']["SpotToAPRS"]
grid=sections['[Configuration]']["MyGrid"]
groups=CSV.parse(sections['[Configuration]']["MyGroups"])[0].map {|n| n.strip}.map {|n| n.gsub('@@','@')}
info=sections['[Configuration]']["MyInfo"]
status=sections['[Configuration]']["MyStatus"]
qth=sections['[Configuration]']["MyQTH"]
station=sections['[Configuration]']["MyStation"]
tcp_enabled=sections['[Configuration]']["TCPEnabled"]
tcp_conns=sections['[Configuration]']["TCPMaxConnections"].to_i
tcp_addr=sections['[Configuration]']["TCPServer"]
tcp_port=sections['[Configuration]']["TCPServerPort"].to_i
hb_sub=sections['[Common]']["SubModeHB"]
tx_freq=sections['[Common]']["TxFreq"].to_i
write_logs=sections['[Configuration]']["WriteLogs"]
beacon_anywhere=sections['[Configuration]']["BeaconAnywhere"]
autoreplyonatstartup=sections['[Configuration]']["AutoreplyOnAtStartup"]
accept_tcp_requests=sections['[Configuration]']["AcceptTCPRequests"]
auto_grid=sections['[Configuration]']["AutoGrid"]
dial_freq=sections['[Common]']["DialFreq"]

puts("Your callsign is configured as #{call}.")
if(grid=="")
  puts("Your grid is unconfigured. Please set at least a four-character grid square.")
else
  puts("Your grid is configured as #{grid}.")
end
if(spot=="true")
  puts("Your SPOT function is turned on. Please disable.")
elsif(spot=="false")
  puts("Your SPOT function is turned off. You're good to go.")
end
if(aprs_spot=="true")
  puts("Your APRS SPOT function is turned on. Please disable.")
elsif(aprs_spot=="false")
  puts("Your APRS SPOT function is turned off. You're good to go.")
end
if(groups.member?("@AMRFTX"))
  puts("Your group membership includes @AMRFTX. Good to go.")
else
  puts("Your group membership does not include @AMRFTX. Please add it.")
end
puts("Your station INFO is set to: #{info}")
puts("Your station STATUS is set to: #{status}")
puts("Your QTH is set to: #{qth}")
puts("Your STATION description is: #{station}")
if(tcp_enabled=="true"&&tcp_conns>0&&tcp_port&&tcp_addr)
  puts("Your system is configured to accept API calls at #{tcp_addr} on TCP port #{tcp_port}.")
else
  puts("Your system is not configured to accept TCP API calls.")
end
if(hb_sub=="true")
  puts("Your system is configured to allow heartbeats outside of the HB sub-band. Good to go.")
else
  puts("Your system is not configured to allow heartbeats outside of the HB sub-band. Please fix this.")
end
if(tx_freq>=1800)
  puts("Your transmission spot on the waterfall is good to go.")
else
  puts("Your transmission spot in the waterfall is too low. Please move up to at least 1800hz.")
end
if(write_logs=="true")
  puts("Your system is configured to write log files. Good to go.")
else
  puts("Your system is not configured to write log files. Please correct this or you will not be able to create maps.")
end
if(beacon_anywhere=="true")
  puts("Your system is allowed to beacon anywhere within the waterfall. Good to go.")
else
  puts("Your system is not allowed to beacon anywhere within the waterfall. Please correct.")
end
if(autoreplyonatstartup=="true")
  puts("Your system is configured to automatically reply. Good to go.")
else
  puts("Your system is not configured to automatically reply. Please correct.")
end
if(accept_tcp_requests=="true")
  puts("Your system allows INFO, STATUS, GRID, etc changes via API. Good to go.")
else
  puts("Your system is does not permit INFO, STATUS, GRID, etc changes via API. Please correct.")
end
if(auto_grid=="true")
  puts("Your system allows INFO, STATUS, GRID, etc changes via API. Good to go.")
else
  puts("Your system is does not permit INFO, STATUS, GRID, etc changes via API. Please correct.")
end
if(dial_freq==7120000)
  puts("Your station is on frequency for the exercise.")
else
  puts("Your station is not on frequency for the exercise. Please set dial frequency of 7120khz.")
end

#binding.pry
