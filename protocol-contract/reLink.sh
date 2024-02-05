#!/bin/bash

echo "4.get arbiter list"
yarn scripts/4setFulfillmentPermission.js --network local

echo "5.data consumer"
yarn scripts scripts/5dataConsumer.js --network local

echo "6.get arbiter list"
yarn scripts scripts/6getArbiterList.js --network local

echo "7.add oralce and jobId"
yarn scripts scripts/6setOralceAndJobId.js --network local

echo "8.call request list"
yarn scripts scripts/8callRequestList.js --network local
