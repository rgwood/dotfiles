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

# Check if zsh is installed
echo -n "Checking for zsh... "
if [[ "$OSTYPE" == "darwin"* ]]; then
	if ! brew list zsh > /dev/null 2>&1; then
		brew install zsh > /dev/null
		echo "installed"
	else
		echo "already installed"
	fi
else
	if ! [ -x "$(command -v zsh)" ]; then
		if [ -x "$(command -v yum)" ]; then
			sudo yum install -y zsh
		elif [ -x "$(command -v apt-get)" ]; then
			sudo apt-get install -y zsh
		else
			echo "unknown package manager!"
			exit 1
		fi
		echo "installed"
	else
		echo "already installed"
	fi	
fi

# Check if oh-my-zsh is installed
echo -n "Checking for oh-my-zsh... "
OMZ_DIR="$HOME/.oh-my-zsh"
if [ ! -d "$OMZ_DIR" ]; then
  /bin/sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" > /dev/null
  echo "installed"
else
  /bin/sh ~/.oh-my-zsh/tools/upgrade.sh > /dev/null 2>&1
  echo "updated"
fi