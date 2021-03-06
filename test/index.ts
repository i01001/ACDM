import { expect } from "chai";
import { BigNumber } from "bignumber.js";
import { ethers, network } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ACDMToken,
  XXXToken,
  Liquidity,
  Staking,
  DAOProject,
  ACDMPlatform,
  LPToken,
} from "../typechain";
import "@nomiclabs/hardhat-web3";

async function getCurrentTime() {
  return (
    await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
  ).timestamp;
}

async function evm_increaseTime(seconds: number) {
  await network.provider.send("evm_increaseTime", [seconds]);
  await network.provider.send("evm_mine");
}

describe("Testing the DAO Project Contract", () => {
  let aCDM: ACDMToken;
  let xXXToken: XXXToken;
  let liquidity: Liquidity;
  let staking: Staking;
  let dAO: DAOProject;
  let aCDMPlatform: ACDMPlatform;
  let lP: LPToken;

  let clean: any;
  let owner: SignerWithAddress,
    signertwo: SignerWithAddress,
    signerthree: SignerWithAddress,
    signerfour: SignerWithAddress;

  before(async () => {
    [owner, signertwo, signerthree, signerfour] = await ethers.getSigners();

    const ACDM = await ethers.getContractFactory("ACDMToken");
    aCDM = <ACDMToken>await ACDM.deploy();
    await aCDM.deployed();

    const XXXT = await ethers.getContractFactory("XXXToken");
    xXXToken = <XXXToken>await XXXT.deploy();
    await xXXToken.deployed();

    const Liquid = await ethers.getContractFactory("Liquidity");
    // const liquidity = await Liquid.attach("0x832E744d07f8f8aC572E449f5Bbe8FeA4fE699ae");
    liquidity = <Liquidity>await Liquid.deploy();
    await liquidity.deployed();

    const Stake = await ethers.getContractFactory("Staking");
    staking = <Staking>await Stake.deploy();
    await staking.deployed();

    const LPT = await ethers.getContractFactory("LPToken");
    lP = <LPToken>await LPT.deploy();
    await lP.deployed();

    const DAO = await ethers.getContractFactory("DAOProject");
    dAO = <DAOProject>(
      await DAO.deploy(owner.address, staking.address, 40, 3600)
    );
    await dAO.deployed();

    const ACDMP = await ethers.getContractFactory("ACDMPlatform");
    aCDMPlatform = <ACDMPlatform>(
      await ACDMP.deploy(aCDM.address, xXXToken.address, dAO.address)
    );
    await aCDMPlatform.deployed();
  });

  describe("Checking the ADCM Platform Contract is run correctly", () => {
    it("Checks the ACDMTokenContract is recorded correctly or not", async () => {
      expect(await aCDMPlatform.ACDMTokenContract()).to.be.equal(
        await aCDM.address
      );
    });

    it("Checks the XXXTokenContract is recorded correctly or not", async () => {
      expect(await aCDMPlatform.XXXTokenContract()).to.be.equal(
        await xXXToken.address
      );
    });

    it("Checks the DAOContract is recorded correctly or not", async () => {
      expect(await aCDMPlatform.DAOContract()).to.be.equal(await dAO.address);
    });

    it("Checks the register function is storing data correctly or not", async () => {
      const _add = "0x0000000000000000000000000000000000000000";
      await aCDMPlatform.connect(owner).register(_add);
      await aCDMPlatform.connect(signertwo).register(owner.address);
      await aCDMPlatform.connect(signerthree).register(signertwo.address);
      const _trade = await aCDMPlatform.Traders(signerthree.address);
      expect(await _trade.refereOne).to.be.equal(await signertwo.address);
      expect(await _trade.refereTwo).to.be.equal(await owner.address);
    });

    it("Checks the register function does not allow referring itself", async () => {
      await expect(
        aCDMPlatform.connect(signerfour).register(signerfour.address)
      ).to.be.revertedWith("invalidrefere()");
    });

    it("Sets the Platform Contract as one of the Owners in ADCM Token", async () => {
      await aCDM.connect(owner).setACDMPlatformaddress(aCDMPlatform.address);
      await expect(await aCDM.connect(owner).Platform()).to.be.equal(
        aCDMPlatform.address
      );
    });

    it("Checks if the nextMode function can be run by non-owner", async () => {
      await expect(
        aCDMPlatform.connect(signerfour).nextMode()
      ).to.be.revertedWith("ownerOnly()");
    });

    it("Checks if the nextMode function can be run by owner", async () => {
      const _check = await aCDMPlatform.connect(owner).nextMode();
      await expect(
        await aCDMPlatform.connect(owner).currentPrice()
      ).to.be.equal(10000000000000);
      await expect(await aCDMPlatform.connect(owner).saleSupply()).to.be.equal(
        100000000000
      );
      await expect(await aCDMPlatform.connect(owner).Mode()).to.be.equal(1);
    });

    it("Checks trade function should not be accessible during Sale mode", async () => {
      await expect(
        aCDMPlatform.connect(owner).createOrder(100, 100)
      ).to.be.revertedWith("invalidmode()");
      await expect(
        aCDMPlatform.connect(owner).redeemOrder(0)
      ).to.be.revertedWith("invalidmode()");
      await expect(
        aCDMPlatform.connect(owner).cancelOrder(0)
      ).to.be.revertedWith("invalidmode()");
    });

    it("Checks buy token function is working correctly", async () => {
      let _oldSignerthreeBalance = await ethers.provider.getBalance(
        signerthree.address
      );
      let _oldSignertwoBalance = await ethers.provider.getBalance(
        signertwo.address
      );
      let _oldowner = await ethers.provider.getBalance(owner.address);
      const _buy = await aCDMPlatform
        .connect(signerthree)
        .buy({ value: ethers.utils.parseEther("0.5") });
      await expect(await aCDMPlatform.connect(owner).saleSupply()).to.be.equal(
        50000000000
      );
      await expect(
        await aCDM.connect(owner).balanceOf(signerthree.address)
      ).to.be.equal(50000000000);
      await expect(
        await ethers.provider.getBalance(aCDMPlatform.address)
      ).to.be.equal(ethers.utils.parseEther("0.46"));
      let _newSignerthreeBalance = await ethers.provider.getBalance(
        signerthree.address
      );
      let _newSignertwoBalance = await ethers.provider.getBalance(
        signertwo.address
      );
      let _newowner = await ethers.provider.getBalance(owner.address);
      expect(await _newSignerthreeBalance).to.be.lt(_oldSignerthreeBalance);
      expect(await _oldSignertwoBalance).to.be.lt(_newSignertwoBalance);
      expect(await _oldowner).to.be.lt(_newowner);
    });

    it("Checks buying tokens more than the supply", async () => {
      const _buy = await aCDMPlatform
        .connect(signerthree)
        .buy({ value: ethers.utils.parseEther("0.6") });
      await expect(await aCDMPlatform.connect(owner).saleSupply()).to.be.equal(
        0
      );
      await expect(
        await aCDM.connect(owner).balanceOf(signerthree.address)
      ).to.be.equal(100000000000);
      await expect(
        await ethers.provider.getBalance(aCDMPlatform.address)
      ).to.be.equal(ethers.utils.parseEther("0.92"));
    });

    it("Checks if supply 0 results in count down timer being set to 0", async () => {
      await expect(
        await aCDMPlatform.connect(owner).currentRoundEndTime()
      ).to.be.lt(await getCurrentTime());
    });

    it("Checks if both Sale related and Trade related functions are blocked", async () => {
      await expect(aCDMPlatform.connect(owner).buy()).to.be.revertedWith(
        "incorrectValue()"
      );
      await expect(
        aCDMPlatform
          .connect(owner)
          .buy({ value: ethers.utils.parseEther("0.1") })
      ).to.be.revertedWith("timeUp()");
      await expect(
        aCDMPlatform.connect(owner).createOrder(100, 100)
      ).to.be.revertedWith("invalidmode()");
      await expect(
        aCDMPlatform.connect(owner).redeemOrder(0)
      ).to.be.revertedWith("invalidmode()");
      await expect(
        aCDMPlatform.connect(owner).cancelOrder(0)
      ).to.be.revertedWith("timeUp()");
    });

    it("Checks if the nextMode function sets the Trade mode", async () => {
      const _check = await aCDMPlatform.connect(owner).nextMode();
      await expect(await aCDMPlatform.connect(owner).Mode()).to.be.equal(2);
    });

    it("Check create order function is working correctly", async () => {
      await aCDM.connect(owner).mint(signertwo.address, 100000000);
      await aCDM.connect(signertwo).approve(aCDMPlatform.address, 100000000);
      const _check = await aCDMPlatform
        .connect(signertwo)
        .createOrder(100000000, ethers.utils.parseEther("1"));
      await expect(
        await (
          await aCDMPlatform.connect(owner).Orders(0)
        )._orderNumber
      ).to.be.equal(0);
      await expect(
        await (
          await aCDMPlatform.connect(owner).Orders(0)
        ).seller
      ).to.be.equal(signertwo.address);
      await expect(
        await (
          await aCDMPlatform.connect(owner).Orders(0)
        ).tokenQuantity
      ).to.be.equal(100000000);
      await expect(
        await (
          await aCDMPlatform.connect(owner).Orders(0)
        ).ethAmount
      ).to.be.equal(ethers.utils.parseEther("1"));
    });

    it("Check redeem order function would not work with value input", async () => {
      await expect(
        aCDMPlatform.connect(signerfour).redeemOrder(0)
      ).to.be.revertedWith("incorrectValue()");
    });

    it("Check redeem order function works correctly", async () => {
      const _oldbalance = await aCDM
        .connect(signerfour)
        .balanceOf(signerfour.address);
      const _oldSpecialbalance = await aCDMPlatform
        .connect(owner)
        .specialBalance();
      await aCDMPlatform
        .connect(signerfour)
        .redeemOrder(0, { value: ethers.utils.parseEther("0.6") });
      const _newbalance = await aCDM
        .connect(signerfour)
        .balanceOf(signerfour.address);
      const _newSpecialbalance = await aCDMPlatform
        .connect(owner)
        .specialBalance();
      expect(await _oldbalance).to.be.lt(_newbalance);
      expect(await _oldSpecialbalance).to.be.lt(_newSpecialbalance);
      let _check = await aCDMPlatform.connect(owner).Orders(0);
      expect(await _check.tokenQuantity).to.be.equal(40000000);
    });

    it("Check cancel order function works correctly", async () => {
      const _obalance = await aCDM
        .connect(signertwo)
        .balanceOf(signertwo.address);
      await expect(
        aCDMPlatform.connect(signerfour).cancelOrder(0)
      ).to.be.revertedWith("notSeller()");
      await aCDMPlatform.connect(signertwo).cancelOrder(0);
      const _nbalance = await aCDM
        .connect(signertwo)
        .balanceOf(signertwo.address);
      expect(await _obalance).to.be.lt(_nbalance);
    });

    it("Check if access to changing parameters blocked", async () => {
      await expect(
        aCDMPlatform.connect(owner).tradeReferrerOneParam(0)
      ).to.be.revertedWith("DAOonly()");
      await expect(
        aCDMPlatform.connect(owner).tradeReferrerTwoParam(0)
      ).to.be.revertedWith("DAOonly()");
      await expect(
        aCDMPlatform.connect(owner).saleReferrerOneParam(0)
      ).to.be.revertedWith("DAOonly()");
      await expect(
        aCDMPlatform.connect(owner).saleReferrerTwoParam(0)
      ).to.be.revertedWith("DAOonly()");
      await expect(
        aCDMPlatform.connect(owner).tradeComissionOwner()
      ).to.be.revertedWith("DAOonly()");
      await expect(
        aCDMPlatform.connect(owner).tradeComissionBurnToken()
      ).to.be.revertedWith("DAOonly()");
    });

    it("Check if current price changes and supply in next round", async () => {
      await expect(await aCDMPlatform.connect(owner).Mode()).to.be.equal(2);
      await expect(aCDMPlatform.connect(owner).nextMode()).to.be.revertedWith(
        "roundinprogress()"
      );
      evm_increaseTime(3 * 24 * 60 * 60);
      await aCDMPlatform.connect(owner).nextMode();
      await expect(await aCDMPlatform.connect(owner).Mode()).to.be.equal(1);
      await expect(
        await aCDMPlatform.connect(owner).currentPrice()
      ).to.be.equal(14300000000000);
      await expect(await aCDMPlatform.connect(owner).saleSupply()).to.be.lt(
        100000000000
      );
    });

    it("Checks if the XXXCoin has the correct Staking Contract stored", async () => {
      await xXXToken.connect(owner).setStakingaddress(staking.address);
      await expect(await xXXToken.connect(owner).Staking()).to.be.equal(
        staking.address
      );
    });

    it("Check the liquidity function works correctly", async () => {
      await xXXToken.connect(owner).mint(owner.address, 1000000);
      await xXXToken.connect(owner).approve(liquidity.address, 1000000);
      await aCDM.connect(owner).mint(owner.address, 10000000000000);
      await aCDM.connect(owner).approve(liquidity.address, 10000000000000);

      const _test = await liquidity.addLiquidity(
        await xXXToken.address,
        await aCDM.address,
        1000000,
        10000000000000
      );
      await _test.wait();

      await expect(
        await xXXToken.connect(owner).balanceOf(owner.address)
      ).to.be.equal(0);
      await expect(
        await aCDM.connect(owner).balanceOf(owner.address)
      ).to.be.equal(0);
    });

    it("Check the staking function works correctly", async () => {
      await lP.connect(owner).setStakingaddress(staking.address);
      await lP.connect(owner).mint(owner.address, 10000000000000);
      await lP.connect(owner).approve(staking.address, 10000000000000);
      await staking.connect(owner).setLPContract(lP.address);
      await staking.connect(owner).setDAOContract(dAO.address);
      await staking.connect(owner).setXXXContract(xXXToken.address);
      await staking.connect(owner).stake(10000000000000);
      await expect(
        await await staking.connect(owner).balance(owner.address)
      ).to.be.equal(10000000000000);
    });

    it("Checking the staking contract to work as expected", async () => {
      await expect(staking.connect(owner).stake(0)).to.be.revertedWith(
        "entergreatervalue()"
      );
      await expect(staking.connect(owner).unstake()).to.be.revertedWith(
        "minimumstakingtime()"
      );
    });

    it("Checking the staking freezing function to work as expected", async () => {
      await staking.connect(owner).freeze();
      await expect(staking.connect(owner).unstake()).to.be.revertedWith(
        await "minimumstakingtime()"
      );
      await evm_increaseTime(24 * 60 * 60);
      await expect(staking.connect(owner).unstake()).to.be.revertedWith(
        "frozen()"
      );
      await staking.connect(owner).freeze();
      await expect(await staking.connect(owner).unstake())
        .to.emit(staking, "_unstake")
        .withArgs(owner.address, 1, 0);
    });

    it("Checking the percentage change function is working correctly or not", async () => {
      await expect(
        staking.connect(signertwo).percentageChange(3)
      ).to.be.revertedWith("ownersonly()");
      await staking.connect(owner).percentageChange(3);
      await expect(await staking.rewardrate()).to.be.equal(3);
    });

    it("Check the DAO proposal function is working correctly", async () => {
      var jsonAbi = [
        {
          inputs: [],
          name: "tradeComissionOwner",
          // outputs: [
          //   {
          //     internalType: "uint256",
          //     name: "temporary",
          //     type: "uint256",
          //   },
          // ],
          stateMutability: "nonpayable",
          type: "function",
        },
      ];

      const iface = new ethers.utils.Interface(jsonAbi);
      const calldata = iface.encodeFunctionData("tradeComissionOwner", []);
      const description = "Send Trade Comission to Owner";

      await expect(
        dAO.connect(owner).newProposal(calldata, aCDMPlatform.address, description)
      );
      await expect(await dAO.connect(owner).proposalID()).to.be.equal(1);
    });


    it("Checks the voting function in the DAO Project", async () => {
      await lP.connect(owner).approve(staking.address, 10000000000000);
      await staking.connect(owner).stake(10000000000000);
      await expect(await staking.connect(owner).balance(owner.address)).to.be.equal(10000000000000);
      await expect(dAO.connect(owner).voting(2, true)).to.be.revertedWith(
        "proposalIDdoesnotexist()"
      );
      await expect(dAO.connect(owner).voting(1, true));
      await expect(dAO.connect(owner).voting(1, true)).to.be.revertedWith(
        "alreadyVoted()"
      );
      let proposalIDlast = await (
        await dAO.connect(owner).proposalID()
      ).toString();
      await expect(await proposalIDlast).to.be.equal("1");

      const voter = await dAO.Voter(owner.address);
      const proposal = await dAO.Proposal(1);
      let time1: any;
      let time2: any;
      let time3: any;
      let timesum: any;
      time1 = await await dAO.debatingPeriodDuration();
      time2 = await proposal.startTime;
      time3 = await voter.endTime;
      timesum = time3 - time1;
      await expect(timesum).to.be.equal(time2);
      await expect(proposal.FORvotes).to.be.equal(10000000000000);
    });

    it("Checks the endProposal function with an incorrect proposal in the DAO Project", async () => {
      await expect(dAO.connect(owner).endProposal(2)).to.be.revertedWith(
        "proposalIDdoesnotexist()"
      );
      await expect(dAO.connect(owner).endProposal(1)).to.be.reverted;
      evm_increaseTime(3600);
    });

    it("Checks the endProposal function for Trade Comission to Owner Proposal", async () => {
      let _oldowner = await ethers.provider.getBalance(owner.address);
      await dAO.connect(owner).endProposal(1);
      let _newowner = await ethers.provider.getBalance(owner.address);
      await expect(await _oldowner).to.be.lt(_newowner);
    });

  });
});
