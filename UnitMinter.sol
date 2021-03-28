/// handles the generation of new units

pragma solidity ^0.8.1;

import "./UnitMarketplace.sol";

interface IUnitMinter is IUnitMarketplace{

}

contract UnitMinter is UnitMarketplace,IUnitMinter{

    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    uint256[] unusedIndices;

    /// @dev creates and stores a new unit
    function _generateUnit(unitType type) internal returns (uint)
    {
        //TODO make this dependent on unit type and less silly
        Unit memory _unit = Unit({
                            attack: randomNumber(3),
                            defence: randomNumber(2),
                            //functions as a multiplier on the other attributes
                            level: 1,
                            //starting health of unit
                            maxHealth: randomNumber(20),
                            // health remaining on this unit
                            curHealth: 0,
                            //what type of unit this is
                            utype: type,
                            //A name associated with this unit
                            name: "default unit name"
                            });

        if (type == unitType.archer) {
            // archer, high attack
            _unit.attack += 15;
            _unit.defence += 1;
            _unit.maxHealth += 50;
        } else if (type == unitType.warrior) {
            // warrior, high defence
            _unit.attack += 10;
            _unit.defence += 5;
            _unit.maxHealth += 50;
        } else {
            // cavalry, high health
            _unit.attack += 10;
            _unit.defence += 1;
            _unit.maxHealth += 75;
        }

        // create units with max health
        _unit.curHealth = _unit.maxHealth;

        //TODO modify this now that unitIDS are permanent
        uint256 newUnitId;
        if(unusedIndices.length == 0){
            units.push(_unit);
            newUnitId = units.length  - 1;
        }else{
            //get the latest unused Index
            newUnitId = unusedIndices[unusedIndices.length - 1];
            //delete from the list of unused Indices since it is now used
            unusedIndices.pop();
        }


        //TODO change how this works. Maybe via auction
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        unitIndexToOwner[newUnitId] = address(this);

        return newUnitId;
    }

    //TODO Add a create unit function to be called by user,
    //     Costs less token if random type chosen
    //     Specific cost token value for chosen unit type
}
