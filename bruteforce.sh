#!/bin/bash

# COMMAND python lastest_hyperopt_to_mongodb.py --config config.json --timeframe 5m --epoch 100 --spaces buy sell --strategy testStrategy --hyperopt Hyperopt --hyperopt-loss hyoperoptloss --timerange 123541 --host lucky

# Checking argrument variable
if [ -z "$1" ]
  then
    echo "Use $0 comment"
    exit;
fi

COMMENT=$1
SECONDS=0

# Loading Variables
source "bruteforce.env"

if [[ "$VIRTUAL_ENV" = "" ]]
then
    echo "Activaing VirtualENV"
    source .env/bin/activate
    echo "Done: $VIRTUAL_ENV"
fi

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
        config="config-$coin-$STAKE_CURRENCY.json"
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
                echo $(timestamp) $FREQTRADE_CMD download-data --config $config -t $timeframe --days $daysDownload
                $FREQTRADE_CMD download-data --config $config -t $timeframe --days $daysDownload
                sleep 10

            done
        done
    done
else
    echo "$(timestamp) No downloading."
fi

echo "$(timestamp) Start Bruteforcing!!!"

for i in $(seq 1 $LOOP); do
    for coin in "${COINS[@]}" ; do
        config="config-$coin-$STAKE_CURRENCY.json"

        for variablePair in "${ARRAY[@]}" ; do
            HyperOpt="${variablePair%%:*}"
            Strategy="${variablePair##*:}"

            for timeframe in ${TIMEFRAMES[@]}; do
                for days in ${DAYSLIST[@]}; do

                    echo "$(timestamp) coin=$coin strategy=$Strategy HYPEROPT_LOSS=$HYPEROPT_LOSS config=$config timeframe=$timeframe epoch=$EPOCH timerange=$timerange "

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
                        echo $(timestamp) $FREQTRADE_CMD hyperopt --spaces $SPACES --strategy $Strategy --hyperopt-loss $HYPEROPT_LOSS --config $config -i $timeframe -e $EPOCH --timerange $timerange
                        $FREQTRADE_CMD hyperopt --spaces $SPACES --strategy $Strategy --hyperopt-loss $HYPEROPT_LOSS --config $config -i $timeframe -e $EPOCH --timerange $timerange
                    else
                        echo $(timestamp) $FREQTRADE_CMD hyperopt --spaces $SPACES --hyperopt $HyperOpt --strategy $Strategy --hyperopt-loss $HYPEROPT_LOSS --config $config -i $timeframe -e $EPOCH --timerange $timerange
                        $FREQTRADE_CMD hyperopt --spaces $SPACES --hyperopt $HyperOpt --strategy $Strategy --hyperopt-loss $HYPEROPT_LOSS --config $config -i $timeframe -e $EPOCH --timerange $timerange
                    fi

                    echo $(timestamp) python lastest_hyperopt_to_mongodb.py --config $config --timeframe $timeframe --epoch $EPOCH --spaces $SPACES --strategy $Strategy --hyperopt $HyperOpt --hyperopt-loss $HYPEROPT_LOSS --timerange $timerange --host $HOST --days $days --comment $COMMENT
                    python lastest_hyperopt_to_mongodb.py --config $config --timeframe $timeframe --epoch $EPOCH --spaces $SPACES --strategy $Strategy --hyperopt $HyperOpt --hyperopt-loss $HYPEROPT_LOSS --timerange $timerange --host $HOST --days $days --comment $COMMENT

                done
            done
        done
    done
done

if [[ "$LINE_NOTIFY_TOKEN" != "" ]]
then
    echo "$(timestamp) Notify LINE"
    curl -X POST -H "Authorization: Bearer $LINE_NOTIFY_TOKEN" -F "message=Bruteforce $COMMENT done. took $SECONDS seconds" https://notify-api.line.me/api/notify
    echo "$(timestamp) Done: $VIRTUAL_ENV"
fi
