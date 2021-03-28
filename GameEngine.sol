/// handles the game calculations and logic etc

pragma solidity ^0.8.1;

import "./SquadBuilder.sol";

interface IGameEngine is ISquadBuilder{
    //TODO add events here
}

/// Handles the actual playing of the game
contract GameEngine is SquadBuilder {

    function unitDeath(uint256 _unitId) internal returns (bool success){
        return true;
    }

    function _attack(uint256 _attackerId,uint256 _defenderId) internal returns(uint256 winnings){
        return 10;
    }

    function _squadBattle(uint attackerSquadId, uint defenderSquadId) internal returns(uint winnings) {
        Squad memory attacker = squads[attackerSquadId];
        Squad storage defender = squads[defenderSquadId];

        require(attacker.state == defender.state);
        require(attacker.state != DeploymentState.Retired);

        Unit[] memory atkUnits;
        Unit[] memory dfdUnits;
        uint atkNum = _getTier(attacker.state);
        uint dfdNum = atkNum;

        for (uint8 i=0; i<atkNum; i++) {
            atkUnits.push(units[attacker.unitIds[i]);
            dfdUnits.push(units[defender.unitIds[i]);
        }

        //TODO include more details wrt squad formation
        //     also include formation in the Squad structure

        uint atkNum = _getTier(attacker.state);
        uint dfdNum = atkNum;
        uint atkIdxAP, atkIdxDP, dfdIdxAP, dfdIdxDP;

        while (atkNum > 0 && dfdNum > 0) {

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
}
