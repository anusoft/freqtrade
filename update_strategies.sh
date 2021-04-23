#!/bin/bash

set -x

if [ ! -d "freqtrade-strategies" ]
then
    echo "Cloning Repository"
    git clone https://github.com/freqtrade/freqtrade-strategies.git
fi

cd freqtrade-strategies
git pull
cd ..
cp freqtrade-strategies/user_data/hyperopts/*.py user_data/hyperopts/
cp freqtrade-strategies/user_data/strategies/*.py user_data/strategies/
cp freqtrade-strategies/user_data/strategies/berlinguyinca/* user_data/strategies/
