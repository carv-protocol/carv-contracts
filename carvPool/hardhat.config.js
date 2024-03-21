require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require('hardhat-deploy')
require("@nomiclabs/hardhat-etherscan");

require('@openzeppelin/hardhat-upgrades');

// url: `https://api-testnet.elastos.io/eth`,

const dotenv = require("dotenv");
dotenv.config({path: __dirname + '/.env'});
const { privateKey,oldPrivateKey} = process.env;

module.exports = {
  
  networks: {

    polygonMumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/F1X0FmmZ95T61-D1LldN5QYam9D0amLn`,
      accounts: [
        "0xa6392433fe30f2bf8564228240eddd41c7ad12ab5332438254054896790ceebe",
        "0xbb568983fe7440b0197b6c990f4249fe83a07d03c7433d82c9d49f8f1e0fea3e",
        "0xadc22517f2de0093429e5365b042da0ec9299353943db0f0cc104743c69104cf",
        "0xada29a473e2b777403e7d2dc3876c5be03ca6b60d97e37e9bd335b1ce05a2680",
        "0xd1179d8889a1c7697d753528571b05d6d95e687ebfa12f03741f7f3d5909870b"
      ]
    },
    
    hardhat:{
      chainId:100,
      accounts: [
        {privateKey:"0xcb93f47f4ae6e2ee722517f3a2d3e7f55a5074f430c9860bcfe1d6d172492ed0",balance:"10000000000000000000000"},
        {privateKey:"0xf143b04240e065984bc0507eb1583234643d64c948e1e0ae2ed4abf7d7aed06a",balance:"10000000000000000000000"},
        {privateKey:"0x49b9dd4e00cb10e691abaa1de4047f9c9d98b72b9ce43e1e12959b22f56a0289",balance:"10000000000000000000000"},
        {privateKey:"0xa6392433fe30f2bf8564228240eddd41c7ad12ab5332438254054896790ceebe",balance:"10000000000000000000000"},
      ],
      blockGasLimit: 8000000
    },

  },

  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ]
  },

  etherscan: {
  }


}

