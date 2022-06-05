import { task } from "hardhat/config";
// import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
// import "@typechain/hardhat";
// import "hardhat-gas-reporter";
// import "solidity-coverage";
import "@nomiclabs/hardhat-web3";


task("stake", "Add tokens to be staked")
.addParam("amount", "Amount to be staked")
.setAction(async (taskArgs,hre) => {
  const [sender, secondaccount, thirdaccount, fourthaccount] = await hre.ethers.getSigners();
  const Staking = await hre.ethers.getContractFactory("Staking");
  const staking = await Staking.deploy();
  await staking.deployed();

  let output = await staking.connect(sender).stake(taskArgs.amount);

console.log(await output);
});