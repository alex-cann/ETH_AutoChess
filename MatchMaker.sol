/// connects players and arranges for who plays what games

pragma solidity ^0.8.1;
//SPDX-License-Identifier: UNLICENSED
import "./GameEngine.sol";
import "./AutoChess.sol";
import "./StoreToken.sol";
import "./GameEngine.sol";
import "./UnitMarketplace.sol";
///handles all the adding of units and whatnot

interface IMatchMaker is IGameEngine{

    function randomChallenge(uint256[] calldata unitIds) external returns (uint256 winnings);
    function targetedChallenge(uint256[] calldata unitIds, uint256 _targetId) external returns (uint256 winnings);
    function withdrawSquad(uint256 _squadId) external returns (bool success);
    function getSquadIdsInTier(DeploymentState _tier) external view returns (uint256[] memory deployed); //This is subject to change

}


contract MatchMaker is IMatchMaker, GameEngine{
    
    /// Calls the parent constructor
    constructor() GameEngine(){
        //Generate some units
        for(uint i=0; i < 7;i++){
            _buyUnit(address(this),UnitType.Cavalry,"DEFAULT");
        }
        //make all the units into a squad
        _createSquad(address(this), ownerToUnitIndices[address(this)]);
    }

    //TODO make this create a squad
    function randomChallenge(uint256[] calldata _unitIds) public override returns (uint256 winnings){
        uint256 squadId;
        DeploymentState tier;
        (squadId, tier) = _createSquad(msg.sender, _unitIds);
        uint256 targetId = randomNumber(tierToSquadIndex[tier].length);
        return _squadBattle(squadId,targetId);
    }


    function targetedChallenge(uint256[] calldata _unitIds, uint256 _targetId) public override returns (uint256 winnings){
        uint256 squadId;
        DeploymentState tier;
        (squadId, tier) = _createSquad(msg.sender,_unitIds);
        //make sure it's a valid target
        assert(tierToSquadIndex[tier].length > _targetId);
        return _squadBattle(squadId,_targetId);
    }


    function getSquadIdsInTier(DeploymentState _tier) public override view returns (uint256[] memory deployed){
        return tierToSquadIndex[_tier];
    }



    function withdrawSquad(uint256 _squadId) public override returns (bool success){

    }
}
