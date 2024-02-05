// @ts-check
import { hardhat } from '@wagmi/cli/plugins';

/** @type {import('@wagmi/cli').Config} */
export default {
  out: './generated-abi.ts',
  contracts: [],
  plugins: [
    hardhat({
      project: '.',
      include: [
        'CarvID.json',
        'Campaigns.json',
        'CampaignsService.json',
        'TestERC20.json'
      ],
    }),
  ],
};