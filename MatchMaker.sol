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

<<<<<<< HEAD
    

=======
>>>>>>> 57bcb0d13a9505f31a3be446b289f34623393568
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
