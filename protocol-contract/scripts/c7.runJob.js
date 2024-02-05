const { 
    sleep ,
    setSession,
    addChainLinkAccount,
    createJob,
    callSetOracleAddJobId,
    setFulfillmentPermission,
    updateJobId
} = require('./utils/helper')


const main = async () => {

    // set session
    await setSession();
    await sleep(2000);

    await addChainLinkAccount();
    await sleep(2000);

    await setFulfillmentPermission();

    await createJob();
    await sleep(2000);
    
    await updateJobId();
    await callSetOracleAddJobId();

}
 

main();
