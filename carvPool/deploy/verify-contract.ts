import { TASK_SOURCIFY } from 'hardhat-deploy';
import { network } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const deploy = async (hre: HardhatRuntimeEnvironment) => {
  if (network.name == 'ronin' || network.name == 'saigon') {
    await hre.run(TASK_SOURCIFY, {
      endpoint: 'https://sourcify.roninchain.com/server',
    });
  }
};

deploy.tags = ['VerifyContracts'];
deploy.runAtTheEnd = true;

export default deploy;