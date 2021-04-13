# CSC2421_ETH_AutoChess

## Sections

1) Introduction
2) Related Work
3) AutoChess
4) Discussion
5) Conclusion

## Introduction

Blockchain provides a decentralized environment to perform consensus and log replication between several nodes. In recent years, blockchain has been used in several different areas to come up with a decentralized solution that enhances their product space or solution space. Most of these advances have happened in the finance domain because of the nature of how blockchain was introduced to the world. Gaming industry is one such field where the introduction and use of blockchain has seen a massive support from the gaming community. A blockchain based game Cryptokitties was so popular when it was launched in 2017 that it had caused a network congestion on the Ethereum network.


Decentralized blockchain applications have provided many benefits that are desirable to the gaming community. One of the most prominent one of them is being able to own and trade in game virtual assets on a common marketplace off game using non fungible tokens that can be logged by the blockchain instead of a central server. There are several other benefits like the core gameplay logic is publicly visible to all and game ownership is not limited to developers only but players themselves can also develop and introduce additional content for these games to the public over the blockchain network.


We introduce AutoChess, a novel blockchain based game that lets users create squads from their units and deploy them into battles with other player's squad for a chance to win tokens. 

The rest of this report is structured as following. Section 2 introduces some related work. Section 3 covers the general design and salient features of AutoChess. Section 4 covers how blockchain is used for AutoChess. Section 5 visits some future direction for AutoChess. Section 6 discusses some issues wrt AutoChess. Section 7 concludes the report.


## Related Work

Initially there were two main types of blockchain games that were developed. First is the Non-fungible token games. Such games introduced non-fungible tokens(NFTs) that users own. Users can then sell these NFT assets. Examples of such games are Cryptokitties, cryptozombies and many more. The Second category of games is gambling games. These games allow users to bet their tokens on some event and then reap rewards based on outcomes. Fomo3d is one such game. With AutoChess we try to include both types of functionality in one game. We allow NFT type units to be owned by users. Users can trade and auction these units.

## AutoChess

This section covers the basic game design of the game and its core features. AutoChess is broadly a battle simulation game inspired by auto battlers like Dota Auto Chess or Team Fight Tactics. It lets players initiate squad battles with other players. The incentive for players is to win these battles to earn rewards. Squads themselves are formed with units, so to build a squad, players need units. Units need to be purchased from the store using tokens which is an investment from the players to play the game. Once a player creates their squad for battle they can challenge the squads of other players. The result of the battle and the winnings if any are then communicated back to the player. There is however more to AutoChess than just a battle simulation and more details follow in the following subsections.

### Features

#### Units
Units that are used to create squads actually participate in the battle individually as explained previously. Each of the units created in AutoChess have the following attributes: level, power, defence, health and name. The level is used when computing the price of the unit as well as the bonus from later level ups. The power determines how much damage the unit does in combat. The defence and health attributes determine the units survivability in combat. The defence of a unit reduces any incoming damage by it's value, whereas health defines how much total damage a unit can sustain, after the reduction from defence. The name is purely cosmetic and allows players to customize their units. Units can level up and receive a bonus to power, health and defence. Total health is linear in level while attack and defence are quadratic.

#### Unit Types
AutoChess allows players to choose from 3 different unit types when buying units from the store. The unit types are Warrior, Archer and Cavalry. Each of these unit types are configured to be better than the other two in one of the 3 main attributes defined above. Warriors have high defence, Archers have high attack, and Cavalry have high health.

#### Squad Tiers
To make the squad battles happen between relatively similar powered squads, AutoChess introduces squad tiers. Players can create squads for different tiers based on how many units are part of it. During a battle only the same tiered squads will engage in battle. There are four tiers with squads sizes of 1,3,5 or 7 units. This ensures players owning more units cannot overpower new members. It also allows players with many units to leverage them for greater rewards, while allowing players with fewer units to still participate.

Because squads can only be attacked after they attack another squad there must be some initial squad for the first player to challenge. This initial squad is in the form of a default all cavalry squad owned by the game. There is one default squad for each tier and after battles the units in the squad are not killed, nor is the squad retired. Therefore, whenever a player challenges one of the default squads the number of deployed squads will increase by one. 

### Battles

Battles are performed as follows. The squads take turns attacking each other but only the damage to the defender is ever saved to the state. The first unit (or a random unit depending on implementation) in each squad deals damage to the last living unit in the other squad. The damage is reduced by the unit receiving damage's defence stat. If a units health would be reduced by 0 it is marked as dead instead. After a fixed number of rounds or when one squad is all dead.
After the battle the defenders state is saved, while the attacker is left unchanged. Tokens are awarded to the owners of each squad based on the value of the units that died (40\% for the defender, and 60\% for the attacker). Any surviving units in the defender are leveled up and receive stat increases. See Appendix \ref{sec:code} for detailed pseudo-code.

## Discussion

### Limited Throughput
One of the major hindrances when using blockchain for backend storage is the limited transaction throughput that the blockchain network supports. With this limitation supporting large multiplayer games with blockchain is an issue. Every action by any player that needs to change the blockchain state becomes a new transaction in the network. So, if the number of players grow the number of transactions being put into the network will also increase. Large number of transactions will then cause network congestion and thus delay in transaction processing. This is more of an issue to games which are more interactive with the transactions they issue for each user action. There are two potential solutions to this issue, one is to batch several actions into a single transaction thereby reducing the effective number of transactions that the blockchain network has to process and replicate to all nodes. Batching is not always possible especially in cases where user actions that change the blockchain state affect or influence the next action that the player has to perform. Second potential solution is to use a blockchain network that allows higher transaction throughput and is thus naturally more scalable to massive multiplayer games. Since, AutoChess is a battle simulation game, the whole battle logic can be batched into a single transaction instead of having single turn based attacks create individual transactions. There are more areas of improvement with respect to batching multiple transactions into one in AutoChess and can be exploited to help reduce the burden of large number of transactions in a limited transaction throughput blockchain network.

### Gas Costs

In addition to the to the low processing speed of blockchain networks another drawback for interactive applications is the transaction fees. Each transaction is charged fees for using network resources (i.e. storage, computation) this includes a base fee of approximately 21000 gas)for any transaction. This means that applications relying on many small updates will be prohibitively expensive to the user due to the base transaction fee. Whereas, applications relying on fewer large updates will have to contend with very large fees that may be off-putting to users and will potentially be less interactive.

We considered several approaches to resolving this issue. However, were ultimately unsuccessful at lowering costs to an acceptable level. The reason for this is that even ignoring the cost of computations related to playing the game, the act of loading, verifying the integrity of, and saving the state required for a battle takes 400,000 gas. 

#### User Submitted Proofs of Computation

One optimization implemented in the Smart Contract is to use a zero knowledge Succinct Non-interactive Arguments of Knowledge to allow users to submit proofs of their results instead of having the smart contract compute the results, allowing for the processing of battles in near fixed time. This process was implemented using the zokrates library and G16 proving scheme. 

Using this process we were able to simulate a battle with 50 rounds at a cost of 400k gas. There are several ways this could be reduced further. There are several other proving schemes for zoKrates that could be used to potentially reduce costs. The zokrates language does not support unbounded iteration and dynamic arrays so squad sizes are padded to 7 with blank units. Since the verifier performs an operation for each input, the cost of verification for small squad sizes is dramatically increased. This could be avoided by creating one verifier for each tier. This is not without drawbacks as the client would have to load an additional key and the contract would have to deploy an additional library for each tier. While this cost is significant it potentially scales much better than computing the whole game on chain. This can be tested using the provided makefile.

However, the front-end still uses the block-chain to compute the result due to the high fixed cost of the zksnark solution making it equally impractical at this point. 

#### Challenge System

Another approach we considered to reduce the gas cost of the contract was to make the battles optimistic in nature. 

Instead of the contract computing the result, the owner of each squad s submits the result of its attack during deployment. This is stored by the contract but not finalized until a later point in time. Until the result is finalized it can be challenged by any party. We finalize the result of an attack after the squad that attacked is itself attacked. As an example, the result of B attacking C is saved at that point, but only finalized once A attacks B.

Additionally,When a squad deploys it is given a grace period during which no other squads can attack it. This guarantees that the owner of the defending squad will have a chance to challenge the results before they are finalized. Detailed pseudo-code is available in Appendix 

There are drawbacks to this approach in that it introduces additional security concerns (e.g. block timestamp manipulation) as well as requires the storing of extra data for each squad that may outweigh the benefits. However, the most significant drawback is that since challenging is more expensive then submitting false results there will be cheating for which the cost of verifying outweighs the damages. This could potentially be mitigated by generating new assets for the aggrieved player but that would come at the cost of further increased challenge costs.

#### Regular Server as a Cache

One optimization we considered but ultimately didn't develop was hosting a web-server and database to offload storage of unnecessary but space consuming state data. Since there is currently no server all persistent information must be stored on the block-chain including strings like the names of units, and auctions. We were able to mimic this to some extent using session storage in the browser. This allows users to create and temporarily save squads without communicating with the block-chain.

If trust in the regular server is high this might yield benefits when combined with the optimistic battle system by reducing the number of transactions that need to be challenged.

### Strategy

Another things that games need to consider is the strategy that invites new players to play the game and keeps the players already playing the game hooked to it. The NFT based games like Cryptokitties have already shown how popular they can be. Being able to own and trade in NFT's is interesting enough for users to play any such game as long as the NFT's in play are interesting to the community. Gambling games however need to consider some strategy to hook players to play the game. AutoChess uses two ways to motivate people to play. First, AutoChess models the battle simulation gameplay in such a way that winning battle is also about strategy than just luck and randomness. Players with better strategy would stand higher chance of winning their squad battles. This itself would make people challenge others to show the world that they are a better strategist. Secondly, AutoChess uses the player's NFT units to issue the gambling based squad battle. Similarly winning squad battles allows players to upgrade their NFT units with some form of battle experience. This way the players who want to play the game for it's NFT auction and trade gameplay have to get involved in the gambling based squad battle to upgrade their units uniquely.
