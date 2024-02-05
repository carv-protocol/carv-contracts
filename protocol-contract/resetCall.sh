#!/bin/bash

#5dataConsumer
echo "5.data consumer"
yarn scripts scripts/5dataConsumer.js --network local

echo "6.get arbiter list"
yarn scripts scripts/6getArbiterList.js --network local

echo "7.add oralce and jobId"
yarn scripts scripts/6setOralceAndJobId.js --network local

echo "8.call request list"
yarn scripts scripts/8callRequestList.js --network local

echo "12.deploy calback test"
yarn scripts scripts/12deployCallbackTest.js --network local

echo "13.register callback"
yarn scripts scripts/13registerCallback.js --network local

# echo "14.quiry By Did"
# yarn scripts scripts/14quiryByDid.js --network local