#!/bin/bash

echo "jsmapper Updater"
echo "Note that this script makes the assumption that you've used the default directories."
echo "If you're smart enough to put it somewhere non-standard, you're probably also smart"
echo "enough to install and update by hand without this script."
echo ""

# See if the file is already checked out.
if test -f ~/jsmapper/jsmapper.rb
then
    echo "It appears that you have jsmapper installed. Updating..."
    echo ""
    cd ~/jsmapper/
    git pull
    chmod a+rx *.rb *.sh
    echo "Done."
    echo ""
    echo ""
    echo ""
    echo "It would be wise to re-run the install.sh script at this point, just in case"
    echo "there are any new library (gem) requirements. The install script will install"
    echo "them, if needed."
else
    echo "Either your installation is horribly broken (in which case you should start"
    echo "over with a fresh download from https://github.com/EchoJuliet-01/jsmapper"
    echo "or you've installed in a non-standard location, in which case, seek assistance"
    echo "on Zello..."
fi
