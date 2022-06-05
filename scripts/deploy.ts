// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  let owner: SignerWithAddress,
    signertwo: SignerWithAddress,
    signerthree: SignerWithAddress;
  [owner, signertwo, signerthree] = await ethers.getSigners();


  const ACDMToken = await ethers.getContractFactory("ACDMToken");
  const aCDMToken = await ACDMToken.deploy();

  await aCDMToken.deployed();
  console.log("ACDMToken deployed to:", aCDMToken.address);


  const XXXToken = await ethers.getContractFactory("XXXToken");
  const xXXToken = await XXXToken.deploy();

  await xXXToken.deployed();
  console.log("XXXToken deployed to:", xXXToken.address);


  const Liquidity = await ethers.getContractFactory("Liquidity");
  const liquidity = await Liquidity.deploy();

  await liquidity.deployed();
  console.log("Liquidity deployed to:", liquidity.address);


  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy();

  await staking.deployed();
  console.log("Staking deployed to:", staking.address);
  

  const DAOProject = await ethers.getContractFactory("DAOProject");
  const dAOProject = await DAOProject.deploy(
    owner.address,
    staking.address,
    40,
    3600
  );

  await dAOProject.deployed();
  console.log("DAOProject deployed to:", dAOProject.address);


  const ACDMPlatform = await ethers.getContractFactory("ACDMPlatform");
  const aCDMPlatform = await ACDMPlatform.deploy(
    aCDMToken.address,
    xXXToken.address,
    dAOProject.address
  );

  await aCDMPlatform.deployed();
  console.log("ACDMPlatform deployed to:", aCDMPlatform.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
