# jsmapper

### Summary

jsmapper is a script that's intended to run on Linux (including the
Raspberry Pi) that analyzes the log files produced by JS8Call, and
produces a CSV file that can be uploaded into the YAAC APRS mapping
package, along with their most recently-reported STATUS and INFO
fields. The intent of this software is to make reporting in AmRRON FTX
exercise easier.

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
The script will ask for sudo credentials (assuming sudo is configured
to ask for crendentials; Raspberry Pi systems are often configured to
not ask for a password), and will install all of the necessary
packages to run.

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
the exercise, BUT WITHOUT ANY "DECORATIONS" (ie, no "/P", "/M",
etc). Upper/lower case does not matter.

The rest of the parameters depend on the way you use JS8Call, and the
results you want from the script. If you have cleared all log data
(ie, removed DIRECTED.TXT and ALL.TXT), and the only data in the log
files is the data from the exercise you want analyzed, no other
parameters are required (unless you want verbose output, with
--verbose). Most people do not clean out their log files manually, so
it's important to use the proper flags to get only the specific data
you want.

It's important to call out the --in-file parameter specifically. The
software is designed to work on Linux (including both x86 and Pi), as
well as a Mac running OSX. It is entirely possible that jsmapper will
work on Windows, though this is untested and unsupported. The install
and update scripts will not work on Windows, and updates and gem
downloads will have to be done manually by the user. Likewise, the
--in-file parameter will likely have to be used to point the script to
the DIRECTED.TXT file in the Windows filesystem.

There are two categories of flags for jsmapper: frequency-related, and
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
If you're a more advanced user, you may wish to read the documentation
for the Ruby 'time' gem, and you'll discover clever ways to do more
with time specifications, like ways to say "last Monday", as well as
specify arbitrary time zones.

It's also perfectly valid to use both frequency and date ranges for
parsing, though since only one frequency range is allowed, this will
not produce accurate results if you operated on more than one band
during the specified time (for example, you operated on both 30M and
40M during the same exercise period).

The output from this script is sent to a file suitable for importing
into YAAC called amrron.csv. Note that old amrron.csv files will be
overwritten when the script is re-run.

### Mapping the Results

Once created, the CSV file can be uploaded to YAAC (note that
installation and configuration of YAAC is not covered by this document
- the requirement is that YAAC is installed and running, and that
you've already downloaded the maps for the location you wish to
visualize). Run YAAC, and then do the following:

1. Click 'File', 'Load', 'APRS Packets'.

2. Ensure that "Files of Type" is "Comma Separated Values".

3. Navigate to the amrron.csv file, then click "Open".

4. Navigate to the log.csv file, and click "Open"

5. Your map should now be populated with each of the reporting
stations.

Clicking on individual markers will display any information that was
gathered regarding that specific station.

EJ-01
