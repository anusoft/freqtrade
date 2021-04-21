#!/bin/bash

# COMMAND python lastest_hyperopt_to_mongodb.py --config config.json --timeframe 5m --epoch 100 --spaces buy sell --strategy testStrategy --hyperopt Hyperopt --hyperopt-loss hyoperoptloss --timerange 123541 --host lucky

# Checking argrument variable
if [ -z "$1" ]
  then
    echo "Use $0 comment"
    exit;
fi

COMMENT=$1

# Loading Variables
source "bruteforce.env"

echo "$(timestamp) Running Bruteforce with comment: $1 on host #$HOST"

# Generate Template
for coin in "${COINS[@]}" ; do
    PAIR="$coin\\/$STAKE_CURRENCY"
    sed "s/__PAIR__/$PAIR/" config-template.json >"config-$coin-$STAKE_CURRENCY.json"
    sed -i "s/__STAKECURRENCY__/$STAKE_CURRENCY/" "config-$coin-$STAKE_CURRENCY.json"
done


# Downloading Data
if $DOWNLOAD; then
    echo "$(timestamp) Start Downloading Data..."
    for coin in "${COINS[@]}" ; do
        config="config-$coin.json"
        for timeframe in ${TIMEFRAMES[@]}; do
            for days in ${DAYSLIST[@]}; do

                daysDownload=$((days+1))

                if [ "$(uname)" == "Darwin" ]; then
                    timestart=$(date -v "-${daysDownload}d" +"%Y%m%d")
                else
                    timestart=$(date -d "${daysDownload} days ago" +"%Y%m%d")
                fi

                timeend=$(date +"%Y%m%d")
                timerange="$timestart-$timeend"

                echo "$(timestamp) Days=$daysDownload timerange=$timerange "
                echo $(timestamp) $FREQTRADE_CMD download-data --config $config -t $timeframe --days $days
                sleep 10

            done
        done
    done
else
    echo "$(timestamp) No downloading."
fi

for coin in "${COINS[@]}" ; do
    config="config-$coin.json"

    for variablePair in "${ARRAY[@]}" ; do
        HyperOpt="${variablePair%%:*}"
        Strategy="${variablePair##*:}"

        for timeframe in ${TIMEFRAMES[@]}; do
            for days in ${DAYSLIST[@]}; do

                if [ "$(uname)" == "Darwin" ]; then
                    timestart=$(date -v "-${days}d" +"%Y%m%d")
                else
                    timestart=$(date -d "${days} days ago" +"%Y%m%d")
                fi
                timeend=$(date +"%Y%m%d")
                timerange="$timestart-$timeend"

                rm -f .tmp.csv
                rm -f user_data/hyperopt_results/.last_result.json

                if [ "$HyperOpt" = "MoniGoManiHyperStrategy" ]; then
                    #$FREQTRADE_CMD hyperopt --spaces $SPACES --strategy $Strategy --hyperopt-loss $hyperopt_loss --config $config -i $timeframe -e $EPOCH --timerange $timerange
                    echo $(timestamp) $FREQTRADE_CMD hyperopt --spaces $SPACES --strategy $Strategy --hyperopt-loss $hyperopt_loss --config $config -i $timeframe -e $EPOCH --timerange $timerange
                else
                    #$FREQTRADE_CMD hyperopt --spaces $SPACES --hyperopt $HyperOpt --strategy $Strategy --hyperopt-loss $hyperopt_loss --config $config -i $timeframe -e $EPOCH --timerange $timerange
                    echo $(timestamp) $FREQTRADE_CMD hyperopt --spaces $SPACES --hyperopt $HyperOpt --strategy $Strategy --hyperopt-loss $hyperopt_loss --config $config -i $timeframe -e $EPOCH --timerange $timerange
                fi

                # COMMAND python lastest_hyperopt_to_mongodb.py --config config.json --timeframe 5m --epoch 100 --spaces buy sell --strategy testStrategy --hyperopt Hyperopt --hyperopt-loss hyoperoptloss --timerange 123541 --host lucky
                # python lastest_hyperopt_to_mongodb.py --config $config --timeframe $timeframe --epoch $EPOCH --spaces $SPACES --strategy $Strategy --hyperopt $HyperOpt --hyperopt-loss $hyperopt_loss --timerange $timerange --host $HOST --days $days --comment $COMMENT
                echo $(timestamp) python lastest_hyperopt_to_mongodb.py --config $config --timeframe $timeframe --epoch $EPOCH --spaces $SPACES --strategy $Strategy --hyperopt $HyperOpt --hyperopt-loss $hyperopt_loss --timerange $timerange --host $HOST --days $days --comment $COMMENT

            done
        done
    done
done
