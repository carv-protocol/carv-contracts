const { 
    sleep ,
    clearPostgres,
    startPostgres
} = require('./utils/helper')

const main = async () => {

    //clear postgres
    await clearPostgres();
    await sleep(2000);

    //start postgres
    await startPostgres();
    await sleep(30000);
   
}

main();
