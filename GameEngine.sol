/// handles the game calculations and logic etc

pragma solidity ^0.8.1;

import "./UnitMinter.sol";

interface IGameEngine is IUnitMinter{
    //TODO add events here
}
///
/// Handles the actual playing of the game
contract GameEngine is UnitMinter,IGameEngine{
    
        function unitDeath(uint256 _unitId) internal returns (bool success){
            return true;
        }
        
        function attack(Squad memory attacker, Squad memory defender) internal returns(uint256 winnings){
            
            
            return true;
        }
        
}
