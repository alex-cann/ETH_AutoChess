/// handles the generation of new units

pragma solidity ^0.8.1;

import "./UnitMarketplace.sol";

interface ISquadBuilder is IUnitMarketplace{

}

contract SquadBuilder is UnitMarketplace, ISquadBuilder {

    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    uint256[] unusedIndices;
    string constant DEFAULT_NAME = "Maurice, the Mediocre";
    /// @dev creates and stores a new unit
    function _generateUnit(UnitType _type,string memory _name) internal returns (uint)
    {
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
                            utype: _type,
                            //A name associated with this unit
                            name: _name
                            });

        if (_type == UnitType.Archer) {
            // archer, high attack
            _unit.attack += 15;
            _unit.defence += 1;
            _unit.maxHealth += 50;
        } else if (_type == UnitType.Warrior) {
            // warrior, high defence
            _unit.attack += 10;
            _unit.defence += 5;
            _unit.maxHealth += 50;
        } else if (_type == UnitType.Cavalry){
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
    
    function _buyUnit(UnitType _type, string memory _name) public returns (uint256 _unitId){
        uint256 _cost = 0;
        uint256 _id;
        if(_type == UnitType.Warrior){
            _cost+=10;
        }else if(_type == UnitType.Archer){
            _cost+=15;
        }else if(_type == UnitType.Cavalry){
            _cost+=20;
        }
        CurrencyProvider.spend(msg.sender,_cost);
        _id = _generateUnit(_type, _name);
        return _id;
    }
    
    function buyUnit(UnitType _type) public returns (uint256 _unitId){
        return _buyUnit(_type, DEFAULT_NAME);
    }
    
    function buyUnit(UnitType _type, string calldata _name) public returns (uint256 _unitId){
        return _buyUnit(_type,_name);
    }
    
    
    function _getTier(uint _unitCount) internal pure returns(DeploymentState state){
        if(_unitCount == 2){
            return DeploymentState.TierOne;
        }else if(_unitCount == 3){
            return DeploymentState.TierTwo;
        }else if(_unitCount == 5){
            return DeploymentState.TierThree;
        }else if(_unitCount == 7){
            return DeploymentState.TierFour;
        }
        //error otherwise
        assert(false);
    }
    
    // create squad
    function _createSquad(uint256[] calldata _unitIds) internal returns(uint256 squadId, DeploymentState tier){
        require(tier != DeploymentState.Retired);
        uint16 atkSum=0;
        for(uint8 i=0; i < _unitIds.length; i++){
            require(unitIndexToOwner[_unitIds[i]] == msg.sender);
            require(unitIndexToState[_unitIds[i]] == UnitState.Default);//check that this unit isn't doing something else
            unitIndexToState[_unitIds[i]] = UnitState.Deployed;
            atkSum+=units[_unitIds[i]].attack;
        }

        DeploymentState _tier = _getTier(_unitIds.length);
        squads.push(Squad({
                    unitIds:_unitIds,
                    unitCount:uint8(_unitIds.length),
                    state:_tier,
                    deployTime:uint16(block.timestamp), //TODO this seems sketch
                    totalAttack:atkSum,
                    stashedTokens:0
                    }));
        return (squads.length ,_tier);
    }
}