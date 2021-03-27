# CSC2421_ETH_AutoChess

## Sections
1) Introduction
2) Game Overview
3) Gameplay
4) Reward System
5) Token and Item Descriptions
6) Unit Marketplace
7) Matchmaking and Ranking
8) Potential ICO Structure
9) Areas for Expansion
10) Contract Details
## Introduction

## Game Overview

## Detailed Gameplay

### Units

#### Leveling Up
Maybe as a result of staying alive for a long time?

#### Upgrades
Maybe?

### Squads
Size?
Types?

### Rounds 


### Victory Conditions
Tokens for killing enemy units
What about a bonus for fully eliminating someone elses squad?

## Reward System

## Token and Item Descriptions

### Token
Tokens can but used to participate in unit auctions or to buy units from other players. Tokens can be created by a user paying ethereum into the smart contract. The token value is pegged to gas costs for the contract.

### Units
values?

## Unit Minting
Units that are destroyed are replaced with randomly generated units. The newly created units are owned by the game contract and will be put up for auction. 
**NOTE**: Add a feature where units can be generated for some fixed amount of coinage

## Unit Marketplace

#### Actions etc
1) List unit(s) for auction
2) Make a bid on an Auction with tokens
3) View auctions in Progress
4) Claim their Tokens from an auction
5) Cancel an auction in progress
6) Hold reverse Auctions (tokens offered for units people put up)
7) Autobidding(potentially set a spend limit etc)


## Matchmaking 


### Challenging Players
There are two different matchmaking modes **Pseudo-Random** and **User Choice**. In **Pseudo-Random** the user is restricted to one opponent chosen at random but potentially known to the user before hand(the randomness comes from the previous blocks hash). In **User Choice** the user can pick any opponent. To balance these options and encourage diverse choices picking **Pseudo-Random** will provide a bonus to any rewards earned.

**NOTE**: ADD details about default squads here

### Being Challenged
Once a player has challenged another user through either **Pseudo-Random** or **User Choice** they will be available as to be challenged. A squad can be challeneged atmost once before it is retired. Additionally, any squad that has been deployed can be recalled for a set amount of tokens calculated based on the time they were deployed for. Eventually, reaching 0 tokens once the squad has been deployed for a sufficiently long time.

### Ranking system

Squads will be divided into tiers based on the number of units in the squad. There will be several tiers with a fixed number of units at each tier. Likely 1,3,5, and 7 units.

## Potential ICO Structure

## GAS fees
Give some mechanism for buying tokens with ethereum which can then be used to pay the gas fees for the contract
How are we covering these?

## Areas for Expansion


## Contract Details

### Structs

### Functions

###
