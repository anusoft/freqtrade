#!env python
# COMMAND python lastest_hyperopt_to_mongodb.py --config config.json --timeframe 5m --epoch 100 --spaces buy sell --strategy testStrategy --hyperopt Hyperopt --hyperopt-loss hyoperoptloss --timerange 123541 --host lucky --comment what-am-i-doing

### REQUIRE LIBRARIES ###
import sys
import json
import os
import argparse

import pandas as pd
import rapidjson
import pymongo


### CONFIGURATION ###
TEMP_CSV_FILE = ".tmp.csv"


MONGO_URL = "mongodb://10.0.0.10:27017/freq"
HYPEROPT_LAST_RESULT = "user_data/hyperopt_results/.last_result.json"

parser = argparse.ArgumentParser(description='Insert Latest Hyperopt to MongoDB')

parser.add_argument('--config', required=True)
parser.add_argument('--timeframe', required=True)
parser.add_argument('--epoch', required=True)
parser.add_argument('--spaces', required=True, nargs='*')
parser.add_argument('--strategy', required=True)
parser.add_argument('--hyperopt', required=True)
parser.add_argument('--hyperopt-loss', required=True)
parser.add_argument('--timerange', required=True)
parser.add_argument('--host', required=True)
parser.add_argument('--days', required=True)
parser.add_argument('--comment', required=True)

args = parser.parse_args()

print('args', args)
print("pymongo.version", pymongo.version)

mongo_client = pymongo.MongoClient(MONGO_URL)
mongo_db = mongo_client.freq
mongo = mongo_db.hyperopt

def GetLastestHyperoptPickle():
    with open(HYPEROPT_LAST_RESULT, 'r') as json_file:
        try:
            data = json.load(json_file)
            return data['latest_hyperopt']
        except:
            return null
    return null

def GetConfigPairs(config_file):
    with open(config_file, 'r') as json_file:
        try:
            data = rapidjson.load(json_file, parse_mode = rapidjson.PM_COMMENTS | rapidjson.PM_TRAILING_COMMAS)
            # print("data", data)
            # print('stake_currency', data['stake_currency'])
            # print('pair_whitelist', data['exchange']['pair_whitelist'])
            

            return {
                'base': data['stake_currency'],
                'pairs': data['exchange']['pair_whitelist']
            }
        except:
            return null
    return null


# Best,Epoch,Trades,Avg profit,Median profit,Total profit,Stake currency,Profit,Avg duration,Objective
#,trigger,sell-trigger,roi_t1,roi_t2,roi_t3,roi_p1,roi_p2,roi_p3,stoploss,hyperopt,strategy,hyperopt-loss,config,i,e,timerange,days

def csv_to_json(filename, last_hyperopt_pickle):

    configPairs = GetConfigPairs(args.config)

    df = pd.read_csv(filename, usecols=['Best','Epoch','Trades','Avg profit','Median profit','Total profit','Stake currency','Profit','Avg duration','Objective'])

    df = df.replace(',','', regex=True)
    df["Total profit"] = df["Total profit"].astype(float)
    df["Profit"] = df["Profit"].astype(float)
    print('days', int((getattr(args, 'days'))))
    days = float( getattr(args, 'days') )

    df['Monthly Profit'] = df['Profit'] / days / 30

    df['pickle'] = last_hyperopt_pickle

    for i in configPairs:
        print('configPairs i', i, configPairs[i], type(configPairs[i]))
        if type (configPairs[i]) is list:
            listValue = configPairs[i]
            df[i] = ",".join(listValue)
        else:
            df[i] = configPairs[i]


    for arg in vars(args):
        if type (getattr(args, arg)) is list:
            listValue = getattr(args, arg)
            df[arg] = ",".join(listValue)
        else:
            df[arg] = getattr(args, arg)

    print(df.head())

    return df.to_dict('records')


last_hyperopt_pickle = GetLastestHyperoptPickle()
if not last_hyperopt_pickle:
    print("No Lastest Hyperopt found")
    sys.exit() 


print('Lastest Hyperopt Found at: ', last_hyperopt_pickle)

os.system("rm -f %s" % TEMP_CSV_FILE)

print('Exporting hyperopt')
os.system(f"freqtrade hyperopt-list --hyperopt-filename %s --best --profitable --min-trades 10 --export-csv %s" % (last_hyperopt_pickle, TEMP_CSV_FILE))

if not os.path.exists(TEMP_CSV_FILE):
    print("No Good Hyperopt found")
    sys.exit() 

print(TEMP_CSV_FILE)


json_data = csv_to_json(TEMP_CSV_FILE, last_hyperopt_pickle)
print('json_data',json_data)

ret = mongo.insert_many(json_data)
print('mongo.insert_many',ret)
