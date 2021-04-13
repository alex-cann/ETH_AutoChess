/// handles the game calculations and logic etc

pragma solidity ^0.8.1;
//SPDX-License-Identifier: UNLICENSED

import "./SquadBuilder.sol";

interface IGameEngine is ISquadBuilder{
    //TODO add events here
    
}

/// Handles the actual playing of the game
contract GameEngine is SquadBuilder,IGameEngine {

    constructor() SquadBuilder(){}
    
    function unitDeath(uint256 _unitId) internal returns (bool success){
        return true;
    }

    //TODO This doesn't match what was discussed on Friday
    function _squadBattle(uint attackerSquadId, uint defenderSquadId) internal returns(uint winnings) {
        Squad memory attacker = squads[attackerSquadId];
        Squad memory  defender = squads[defenderSquadId];

        require(attacker.state == defender.state);
        require(attacker.state != DeploymentState.Retired);
        
        //Making these storage variables is very dubious
       
        uint8 atkNum = attacker.unitCount;
        uint8 dfdNum = defender.unitCount;
        Unit[] memory atkUnits = new Unit[](atkNum);
        Unit[] memory dfdUnits = new Unit[](dfdNum);
        
        for (uint8 i=0; i<atkNum; i++) {
            atkUnits[i] = units[attacker.unitIds[i]];
            dfdUnits[i] = units[defender.unitIds[i]];
        }

        //TODO include more details wrt squad formation
        //     also include formation in the Squad structure
        uint atkIdxAP;
        uint atkIdxDP;
        uint dfdIdxAP;
        uint dfdIdxDP;

        while (atkNum > 0 && dfdNum > 0) {
            //TODO why is this random ordering it allows for users to structure squads better
            //otherwise why does it matter that you have warriors etc if enemies will randomly hit your archers
            
            // attacker attacks phase
            // choose attacker unit
            atkIdxAP = randomNumber(attacker.unitIds.length);
            while(atkUnits[atkIdxAP].curHealth <= 0) {
                atkIdxAP = (atkIdxAP + 1) % attacker.unitIds.length;
            }

            // choose defending unit
            dfdIdxAP = randomNumber(defender.unitIds.length);
            while(dfdUnits[dfdIdxAP].curHealth <= 0) {
                dfdIdxAP = (dfdIdxAP + 1) % defender.unitIds.length;
            }

            // attack happens
            // TODO maybe add fancy stuff here
            //      like counter attack or something similar
            dfdUnits[dfdIdxAP].curHealth -= (atkUnits[atkIdxAP].attack - dfdUnits[dfdIdxAP].defence);

            if (dfdUnits[dfdIdxAP].curHealth <= 0) {
                //TODO handle unit death
                dfdNum--;
            }

            // defender attacks phase
            // choose attacker unit
            atkIdxDP = randomNumber(defender.unitIds.length);
            while(dfdUnits[atkIdxDP].curHealth <= 0) {
                atkIdxDP = (atkIdxDP + 1) % defender.unitIds.length;
            }

            // choose defender unit
            dfdIdxDP = randomNumber(attacker.unitIds.length);
            while(atkUnits[dfdIdxDP].curHealth <= 0) {
                dfdIdxDP = (dfdIdxDP + 1) % attacker.unitIds.length;
            }

            // attack happens
            atkUnits[dfdIdxDP].curHealth -= (dfdUnits[atkIdxDP].attack - atkUnits[dfdIdxDP].defence);

            if (atkUnits[dfdIdxDP].curHealth <= 0) {
                //TODO handle unit death
                atkNum--;
            }
        }

        // copy defender squad units state back to chain
        for (uint8 i=0; i<dfdUnits.length; i++) {
            units[defender.unitIds[i]] = dfdUnits[i];
        }
        defender.unitCount = dfdNum;
        // TODO should squad be retired if all died

        if (atkNum == 0) {
            // attacker lost the battle
            return 0;
        } else {
            // calculate winnings here
            // for now returning static value of 10
            return 10;
        }
    }
    
    function _verify(uint attackerSquadId, uint defenderSquadId) internal returns(uint winnings){
        Squad memory attacker = squads[attackerSquadId];
        Squad memory  defender = squads[defenderSquadId];

        require(attacker.state == defender.state);
        require(attacker.state != DeploymentState.Retired);
        
        //Making these storage variables is very dubious
       
        uint8 atkNum = attacker.unitCount;
        uint8 dfdNum = defender.unitCount;
        Unit[] memory atkUnits = new Unit[](atkNum);
        Unit[] memory dfdUnits = new Unit[](dfdNum);
        
        for (uint8 i=0; i<atkNum; i++) {
            atkUnits[i] = units[attacker.unitIds[i]];
            dfdUnits[i] = units[defender.unitIds[i]];
        }
        
        
        
    }
    
}
