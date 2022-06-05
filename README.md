
# ACDM Platform for Trading Tokens 



## Features

Platform will consist of several contracts (ACDMToken, XXXToken, Staking, DAO, ACDMPlatform, Liquidity).

Description of ACDMToken
name = ACADEM Coin
symbol = ACDM
decimals = 6

Description of XXXToken
name = XXXCoin
symbol = XXX
decimals = 18

XXXToken is listed on uniswap. The initial price of the token is 0.00001 ETH.

Staking Contract

- Contract accepts LP tokens (XXX/ETH)
- Staked tokens are locked for X_days after this time they can withdraw their tokens
- If Staked Tokens are used by user to participate in voting, then cannot withdraw tokens until voting ends
- Every week, users are awarded a reward, 3% of their contribution. 
- The reward can be withdrawn at any time.
- The reward is credited in XXXToken.
- X_days is only set by DAO voting.


DAO Contract

- To participate in DAO voting, a user needs to make a staking deposit. 
- The voting weight depends on the staking deposit (For example: I staked 100 LP, taking part in the voting I have a weight of 100 votes).


ACDM Platform

There are 2 rounds "Trade" and "Sell", which follow each other, starting with the round of sale.
Each round lasts 3 days.

Basic concepts:
- Round "Sale" - In this round, the user can buy ACDM tokens at a fixed price from the platform for ETH.
- Trade round - in this round, users can buy ACDM tokens from each other for ETH.
- Referral program - the referral program has two levels, users receive rewards in ETH.

"SALE" Round
- The price of the token grows with each round and is calculated by the formula (Round 1: 0.0000100; consecutive Rounds (Previous Round)*1.03+0.000004). 
- The number of issued tokens in each Sale round is different and depends on the total trading volume in the Trade round. 
- The round may end early if all tokens have been sold. 
- At the end of the round, unsold tokens are burned.

"TRADE" Round
- Users place orders to sell ACDM tokens for a certain amount in ETH. 
- Buyers redeems tokens for ETH. 
- The order may not be fully redeemed. 
- Also, the order can be canceled and the user will get his tokens back, which have not yet been sold. 
- The received ETH is immediately sent to the user in their metamask wallet. 
- At the end of the round, all open orders move to the next TRADE round.

Referral Program
- When registering, the user indicates his referrer (The referrer must already be registered on the platform).
- When buying ACDM tokens in the Sale round:
- Referrer_1 will receive 5% (this parameter is regulated through DAO) of its purchase, 
- Referrer_2 will receive 3% (this parameter is regulated through DAO)
- The platform itself will receive 92%, in the absence of referrers, the platform receives everything.


When buying in the Trade round:
- The user who placed an order to sell ACDM tokens will receive 95% ETH 
- Referrers will receive 2.5% (this parameter is regulated through DAO)
- In case of their absence, the platform takes these percentages to a special account, to which access there is only through DAO voting.
- DAO voting - users will decide to give this commission to the owner or buy XXXTokens on uniswap with these ETH and then burn them.
## Verified Contracts - Rinkeby


liquidity: 0x832E744d07f8f8aC572E449f5Bbe8FeA4fE699ae  https://rinkeby.etherscan.io/address/0x832e744d07f8f8ac572e449f5bbe8fea4fe699ae#code

XXXCoin: 0x4E20A1628f2a49523C20aD41fe117Aa794e4560F  https://rinkeby.etherscan.io/address/0x4e20a1628f2a49523c20ad41fe117aa794e4560f#code

Staking: 0x7806D6222d81A3FbCfe82e91Edf46dEA3F8a7e0A https://rinkeby.etherscan.io/address/0x7806d6222d81a3fbcfe82e91edf46dea3f8a7e0a#code

ACDM Token: 0x654b7302daB0527AD4FA0dA487998Db9b0c2Ac55 https://rinkeby.etherscan.io/address/0x654b7302dab0527ad4fa0da487998db9b0c2ac55

DAO: 0x17a64C715aE43FDee404a94FbDD606E182E37a57 https://rinkeby.etherscan.io/address/0x17a64c715ae43fdee404a94fbdd606e182e37a57

ACDM Platform:  0x7Ce39Ea8E4682E715EC9755771FFfE53D627b67A https://rinkeby.etherscan.io/address/0x7ce39ea8e4682e715ec9755771fffe53d627b67a


Adding Liqudity to XXX / ETH pair on Uniswap: https://rinkeby.etherscan.io/tx/0x25ef08c39d515de63e46aa45a1f339951fa7a17903ae2c30109f7111f53b63a7



## Authors

- [@Ikhlas](https://www.github.com/i01001)


## Tech Stack

Solidity, Hardhat, Typescript, Ethersjs


## Feedback

If you have any feedback, please reach out to me on my email ikhlaskhan007@gmail.com or on Discord i0001#3442
