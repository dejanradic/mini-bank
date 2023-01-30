import { HardhatUserConfig } from 'hardhat/types';
import { task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import 'dotenv/config';


task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(await account.address);
  }
});
export default {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500
      }
    }
  },
  namedAccounts: {
    deployer: 0,
    // @TODO replace with proper address
    team: 0,
    // @TODO replace with proper address
    stakingContract: 0

  },
} as HardhatUserConfig
