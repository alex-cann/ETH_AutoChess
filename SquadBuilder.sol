pragma solidity ^0.8.1;
//SPDX-License-Identifier: UNLICENSED

import "./UnitMarketplace.sol";

interface ISquadBuilder is IUnitMarketplace{
    function buyUnit(UnitType _type) external returns (uint256 _unitId);
    function buyUnit(UnitType _type, string calldata _name) external returns (uint256 _unitId);
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
        return newUnitId;
    }
    
    function _buyUnit(address _owner, UnitType _type, string memory _name) public returns (uint256 _unitId){
        uint256 _cost = 0;
        uint256 _id;
        if(_type == UnitType.Warrior){
            _cost+=10;
        }else if(_type == UnitType.Archer){
            _cost+=15;
        }else if(_type == UnitType.Cavalry){
            _cost+=20;
        }
        CurrencyProvider.spend(_owner,_cost);
        _id = _generateUnit(_type, _name);
        unitIndexToOwner[_id] = _owner;
        ownerToUnitCount[_owner]+=1;
        ownerToUnitIndices[_owner].push(_id);
        return _id;
    }
    
    function buyUnit(UnitType _type) public override returns (uint256 _unitId){
        return _buyUnit(msg.sender, _type, DEFAULT_NAME);
    }
    
    function buyUnit(UnitType _type, string calldata _name) public override returns (uint256 _unitId){
        return _buyUnit(msg.sender,_type,_name);
    }
    
    
    // create squad
    //TODO remove the workaround where you have to send 7 unitIds
    function _createSquad(address _owner, uint256[] memory _unitIds) internal returns(uint256 squadId, DeploymentState tier){
        uint16 atkSum=0;
        //TODO make sure that _unitIds is one of the correct lengths
        for(uint8 i=0; i < _unitIds.length && i < 7; i++){
            require(unitIndexToOwner[_unitIds[i]] == msg.sender, "You don't own this unit!");
            require(unitIndexToState[_unitIds[i]] == UnitState.Default);//check that this unit isn't doing something else
            unitIndexToState[_unitIds[i]] = UnitState.Deployed;
            atkSum+=units[_unitIds[i]].attack;
        }

        DeploymentState _tier = _getTier(_unitIds.length);
        squads.push(Squad({
                    unitIds: new uint256[](0),
                    unitCount:uint8(_unitIds.length),
                    state:_tier,
                    deployTime:uint16(block.timestamp), //TODO this seems sketch
                    totalAttack:atkSum,
                    stashedTokens:0
                    }));
        //TODO figure out a better way of making this work
        //https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb
         for(uint8 i=0; i < _unitIds.length && i < 7; i++){
            squads[squads.length - 1].unitIds.push(_unitIds[i]);
        }
        ownerToSquadIndex[_owner].push(squads.length -1);
        squadIndexToOwner[squads.length - 1] = _owner;
        return (squads.length-1,_tier);
    }
}
