/// connects players and arranges for who plays what games

pragma solidity ^0.8.1;
import "./GameEngine.sol";
import "./AutoChess.sol";
import "./StoreToken.sol";
import "./GameEngine.sol";
import "./UnitMarketplace.sol";
///handles all the adding of units and whatnot

interface IMatchMaker is IGameEngine{
    
    function randomChallenge(uint256 _squadId) external returns (uint256 winnings);
    function targetedChallenge(uint256 _squadId, uint256 _targetId) external returns (uint256 winnings);
    function withdrawSquad(uint256 _squadId) external returns (bool success);
    function viewSquadsByState(IAutoChessBase.DeploymentState _state) external view returns (IAutoChessBase.Squad[] memory deployed); //This is subject to change
    
}


contract MatchMaker is GameEngine, IMatchMaker{
    
    
    function _withdraw(uint256 _squadId) internal returns(bool success){
        
      
    }
    
    //TODO maybe move this to unit minter
    function _createSquad(uint256[] calldata _unitIds) internal returns(uint256 squadId){
        uint256 atkSum=0;
        for(uint8 i=0; i < _unitIds.length; i++){
            require(unitIndexToOwner(_unitIds[i]) == msg.sender);
            require(unitIndexToState[_unitIds[i]] == UnitState.Default);//check that this unit isn't doing something else
            unitIndexToState[_unitIds[i]] = UnitState.Deployed;
            atkSum+=units[_unitIds[i]];
        }
        
        DeploymentState tier = _getTier(_unitIds.length);
        squads.push(Squad({
            unitIds:_unitIds,
            unitCount:_unitIds.length,
            state:tier,
            deployTime:now,
            totalAttack:atkSum
        }));
    }
   
    function _deploy(uint256[] memory _unitIds) internal returns(uint256 squadId){
        
        
    }
    
    function _getTier(uint _unitCount) internal view returns(DeploymentState state){
        if(_unitCount == 1){
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
    
    function _challenge(Squad memory _squad, uint256 _targetId) internal returns (uint256 winnings){
        
        
    }
    
    
    //TODO make this create a squad
    function randomChallenge(uint256 _squadId) public override returns (uint256 winnings){
        assert(msg.sender == squadIndexToOwner[_squadId]);
        Squad memory squad = squads[_squadId];
       
    }
    
    
    function targetedChallenge(uint256 _squadId, uint256 _targetId) public override returns (uint256 winnings){
        assert(msg.sender == squadIndexToOwner[_squadId]);
        Squad memory squad = squads[_squadId];
        return _challenge(squad,_targetId);
    }
    
    
    function getSquadIdsInTier(DeploymentState _tier) public override view returns (uint256[] memory deployed){
        return tierToSquadIndex[_tier];
    }
    
    
    
    function withdrawSquad(uint256 _squadId) public override returns (bool success){
        
    }
}
