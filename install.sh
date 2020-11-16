#!/bin/bash

echo "jsmapper Installer"
echo "Note that this script makes the assumption that you've used the default directories."
echo "If you're smart enough to put it somewhere non-standard, you're probably also smart"
echo "enough to install and update by hand without this script."

# First, let's make sure ruby is installed.
echo ""
echo "First, see if ruby is installed. If it's not, install it..."
if [ `which ruby | egrep -c "\/ruby$"` -eq 1 ]
then
    echo "Ruby is installed."
else
    echo "Ruby is not installed. Installing..."
    sudo apt install ruby ruby-dev
    echo ""
    if [ `which ruby | egrep -c "\/ruby$"` -eq 1 ]
    then
	echo "Ruby is installed."
    else
	echo "Unable to install Ruby. Install failed. Exiting..."
	exit
    fi
fi

# If ruby is installed, gem *should* also be installed, but it would
# be dumb to make assumptions, so let's check.
echo ""
if [ `which gem | egrep -c "\/gem$"` -eq 1 ]
then
    echo "The gem binary is installed."
else
    echo "The gem binary is missing. Something is broken. Exiting."
    echo "Unable to install Ruby. Install failed. Exiting..."
    exit
fi

# Now let's install the two extra gems we're going to need.
echo ""
echo "Installing gems (if already installed, they'll be updated)."
sudo gem install optimist maidenhead

# Make sure git is installed.
echo ""
echo "First, see if git is installed. If it's not, install it..."
if [ `which git | egrep -c "\/git$"` -eq 1 ]
then
    echo "Git is installed."
else
    echo "Git is not installed. Installing..."
    sudo apt install git
    echo ""
    if [ `which git | egrep -c "\/git$"` -eq 1 ]
    then
	echo "Git is installed."
    else
	echo "Unable to install Git. Install failed. Exiting..."
	exit
    fi
fi

# See if the file is already checked out.
echo ""
if test -f ~/jsmapper/jsmapper.rb
then
    echo "It appears that jsmapper has already been downloaded. If you're getting errors"
    echo "or having problems with it, you can remove the ~/jsmapper directory and start over"
    echo "with a fresh download (follow the instructions at https://github.com/EchoJuliet-01/jsmapper)"
    echo ""
    echo "If you need to update jsmapper, run the update.sh script."
    echo ""
else
    echo "Downloading jsmapper..."
    git clone https://github.com/EchoJuliet-01/jsmapper.git
fi

# Make sure permissions are correct everywhere.
cd ~/jsmapper/
chmod a+rx *.rb *.sh

echo "Done."
