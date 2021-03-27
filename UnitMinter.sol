/// handles the generation of new units

pragma solidity ^0.8.1

import "./UnitToken.sol";

contract UnitMinter is UnitToken{
    
    
    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    uint256[] unusedIndices;
    
    // Predictable random number generator. Used for unit generation
    //the 
    //from https://fravoll.github.io/solidity-patterns/randomness.html
    function randomNumber(uint options) internal view returns (uint16) {
        return uint16(uint(blockhash(block.number - 1)) % options);
    }

    
    /// @dev creates and stores a new unit
    function _generateUnit() internal returns (uint)
    {
        //TODO make this dependent on unit type and less silly
        Unit memory _unit = Unit({
            attack: 5 + randomNumber(2),
            defence: 5 + randomNumber(2),
            //functions as a multiplier on the other attributes
            level: 1,
            //starting health of unit
            maxHealth: 5 + randomNumber(2),
            // health remaining on this unit
            curHealth: 5 + randomNumber(2),
            //what type of unit this is
            utype: unitType(randomNumber(2)),
            //A name associated with this unit
            name: "default unit name"
        });
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
}
