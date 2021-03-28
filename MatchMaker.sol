/// connects players and arranges for who plays what games

pragma solidity ^0.8.1;
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
    function getSquadIdsInTier(IAutoChessBase.DeploymentState _tier) external view returns (uint256[] memory deployed); //This is subject to change

}


contract MatchMaker is IMatchMaker, GameEngine{


    function _withdraw(uint256 _squadId) internal returns(bool success){


    }

    //TODO maybe move this to unit minter
    function _createSquad(uint256[] calldata _unitIds) internal returns(uint256 squadId, DeploymentState tier){
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


    function _getTier(uint _unitCount) internal pure returns(DeploymentState state){
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

    function _challenge(uint256 _squadId, uint256 _targetId) internal returns (uint256 winnings){


    }


    //TODO make this create a squad
    function randomChallenge(uint256[] calldata _unitIds) public override returns (uint256 winnings){
        uint256 squadId;
        DeploymentState tier;
        (squadId, tier) = _createSquad(_unitIds);
        uint256 targetId = randomNumber(tierToSquadIndex[tier].length);
        return _attack(squadId,targetId);
    }


    function targetedChallenge(uint256[] calldata _unitIds, uint256 _targetId) public override returns (uint256 winnings){
        uint256 squadId;
        DeploymentState tier;
        (squadId, tier) = _createSquad(_unitIds);
        //make sure it's a valid target
        assert(tierToSquadIndex[tier].length > _targetId);
        return _attack(squadId,_targetId);
    }


    function getSquadIdsInTier(DeploymentState _tier) public override view returns (uint256[] memory deployed){
        return tierToSquadIndex[_tier];
    }



    function withdrawSquad(uint256 _squadId) public override returns (bool success){

    }
}
