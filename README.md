# jsmapper

### Summary

The jsmapper is a script that's intended to run on Linux (including
the Raspberry Pi) that analyzes the log files produced by JS8Call, and
produces two CSV files suitable for importing into Google Maps to
visualize the distribution of exercise participants, along with their
most recently reported INFO and STATUS messages.

### Installation

The script is written in Ruby, and requires several gems to
operate. There is an install script that will go fetch all of the
necessary files for this tool to run.

In order to install this script on your system for the first time, run
the following commands:
````
cd
git clone https://github.com/EchoJuliet-01/jsmapper.git
cd
cd ~/jsmapper/
./setup.sh
````
The script will ask for sudo credentials (if you have that configured
on your system, Raspberry Pi systems often do not), and will install
all of the necessary packages to run.

If the 'git' command fails, you'll need to install it. Run this
command, then try the above again:
````
sudo apt install git
````
If you already have jsmapper installed, and simply want to make sure
you're running the latest version of code, run the update script:
````
cd ~/jsmapper/
./update.sh
````
Again, the script may ask for sudo credentials if your system is
configured to do so, and if required by the script.

### Operation

Once the script is installed and/or updated, it's ready to run. If run
with the --help option, the script will show you the available
parameters:
````
amrron@amrron:~/jsmapper$ ./jsmapper.rb --help
Options:
  -m, --mycall=<s>        My Call Sign
  -d, --dial-freq=<s>     Dial Frequency (in khz, defaults to all logged traffic)
  -b, --bandwidth=<s>     Bandwidth (in khz, defaults to 3khz)
  -s, --start-time=<s>    Start time/date (YYYY/MM/DD HH:MM:SS, system time zone)
  -e, --end-time=<s>      End time/date (YYYY/MM/DD HH:MM:SS, system time zone)
  -i, --in-file=<s>       JS8Call log file (defaults to ~/.local/share/JS8Call/DIRECTED.TXT)
  -v, --verbose           Spew verbose logging data
  -h, --help              Show this message
amrron@amrron:~/jsmapper$
````
The --mycall parameter is mandatory. This must match the call used in
the exercise, WITHOUT ANY "DECORATIONS" (ie, no "/P", "/M",
etc). Upper/lower case does not matter.

The rest of the parameters depend on the way you use JS8Call, and the
results you want from the script. If you have cleared all log data
(ie, wiped out DIRECTED.TXT and ALL.TXT), and the only data in the log
files is the data from the exercise you want analyzed, no other
parameters are required (unless you want verbose output, with
--verbose). Most people do not clean out their log files manually, so
it's important to use the proper flags to get the specific data you
want.

There are two categories of flags: frequency-related, and
time-related. Frequency-related flags allow you to specify the dial
frequency you used for the exercise (for example, 7078khz) and the
bandwidth of the passband (defaults to 3khz, and it's unlikely you'll
want to change this). For example, if you want to capture all data
(from all dates/times) from the log file between 7078khz and 7091khz
(the typicall passband for the standard 40m JS8Call frequency), you'd
run the following command:
````
amrron@amrron:~/jsmapper$ ./jsmapper.rb --mycall N0CLU --dial-freq 7078
````
Note that this will process ALL log data from that frequency,
including all historical data as far back as the log goes. It's more
likely that you'll want to bound the processes to a specific time
period. Note that all specified dates and times are specified in the
time zone your system is configured for, not GMT (unless you happen to
have your system time zone set to GMT). If the exercise ran from 8am
last Saturday until noon last Sunday, and you wanted all activity
during that time period (not limited to a specific frequency range),
you could run the following command (note the double-quotes around any
parameters that include a space):
````
amrron@amrron:~/jsmapper$ ./jsmapper.rb --mycall N0CLU --start-time "2020/11/7 8:00:00" --end-time "2020/11/8 12:00:00"
````
If you're a more advanced user, go read the documentation for the Ruby
time library, and you'll discover clever ways to do more with time
specifications, like ways to say "last Monday", as well as specify
arbitrary time zones. If you're not that kind of user, just stick with
the basic date/time format above.

It's also perfectly valid to use both frequency and date ranges for
parsing, though since only one frequency range is allowed, this will
not produce accurate results if you operated on more than one band
during the specified time (for example, 30M and 40M).

Last, but not least, note that there are flags for specifying the
input and output files. If you've done a standard Linux JS8Call
installation, there is no need to specify your input file. The program
will default to the standard location for this file. If, however, you
have a non-standard installation, or if you want to process a
DIRECTED.TXT file sent to you by another user, you can specify the
location of this file using the --in-file flag.

The output from this script is sent to two files suitable for
importing into Google maps. The file with_calls.csv includes call
signs in the data, and the file without_calls.csv does not. Either can
be uploaded and mapped successfully, depending on your desired level
of privacy. Note that old files with the same name will be
overwritten.

### Mapping the Results

Once created, the CSV file can be uploaded to Google Maps. Click on
the following link, then log in with your Google account (if not
already logged in):

https://www.google.com/mymaps

1. Click on the "Create a new map" link (or click on a map you want to
   overwrite/update)

2. In the white box in the upper left, click "Import"

3. Click "Select a file from your device"

4. Navigate to the with_calls.csv or without_calls.csv file, and click
   "Open"

5. The dialog that pops up should have "Lat" and "Lon" clicked. If
   not, click them, then click "Continue"

6. For the Title dialog, choose "Call", and click "Finish"

7. Current versions of My Maps have a bug where the Title selection is
   sometimes ignored. Click "Uniform Style" in the white box, then
   under "Set Labels", choose "Call"

8. You should now have a Google Map with markers with call signs next to them

Clicking on the individual markers should produce relevant info for
that call sign, including Call, Lat, Lon, Info (if any), and Status
(if any). If you wish, you may label your map, choose the map style,
and export or share this map with other users.

### Future Features

Future versions of this code will likely use a mapping solution other
than Google Maps. While Google Maps are clearly the leader in this
technology, there are privacy implications of pushing this data to the
web in general, and to Google, specifically. Self-contained (ie,
non-web) solutions are being investigated. While they will almost
certainly produce inferior results visually, they should be
considerably more secure.

Future versions will also make better use of the available log data
that is currently discarded. For example, very detailed data is
available regarding signal strength between arbitrary received
stations (with specifics regarding band, time of day, and solar
conditions, allowing for predictive use for future communications), as
well as connectivity and path information. It should also be trivial
to group stations into "social groups" based on observed
communications patterns. Some simple traffic analysis should also be
able to show patterns of communications and/or "traffic hubs" within
the groups of users based on usage data.

EJ-01
