#!/bin/bash

# Check if homebrew is installed
echo -n "Checking for homebrew... "
if [[ "$OSTYPE" == "darwin"* ]]; then
	if [ -x "$(command -v brew)" ]; then
		echo -n "installing... "
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" > /dev/null 2>&1
		echo "installed"
	else
		echo "already installed"
	fi
else
	echo "not applicable"
fi

# Check if fish is installed
echo -n "Checking for fish... "
if [[ "$OSTYPE" == "darwin"* ]]; then
	if ! brew list fish > /dev/null 2>&1; then
		brew install fish > /dev/null
		echo "installed"
	else
		echo "already installed"
	fi
else
	if ! [ -x "$(command -v fish)" ]; then
		if [ -x "$(command -v yum)" ]; then
			sudo yum install -y fish
		elif [ -x "$(command -v apt-get)" ]; then
			sudo apt-add-repository ppa:fish-shell/release-3
			sudo apt-get update
			sudo apt-get install fish
		else
			echo "unknown package manager!"
			exit 1
		fi
		echo "installed"
	else
		echo "already installed"
	fi	
fi