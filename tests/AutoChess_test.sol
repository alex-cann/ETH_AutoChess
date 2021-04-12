pragma solidity ^0.8.1;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "../MatchMaker_flat.sol";


library testFunctions{
    
    function testBuyUnit (MatchMaker target, StoreToken token) public {
        uint256 initialBalance = token.balanceOf(address(this));
        uint256 initialUnits = target.balanceOf(address(this));
        target.buyUnit(UnitType.Archer);
        target.buyUnit(UnitType.Warrior);
        target.buyUnit(UnitType.Cavalry, "short name");
    }
    
    function testCreateAuction (MatchMaker target, StoreToken token) public {
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.startAuction(unitIds, 500, "It's a me");

    }
    
    
    function testCreateSquad(MatchMaker target, StoreToken  token) public {
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       require(unitIds.length == 3, "buying units failed");
       target.targetedChallenge(unitIds,2);
    }
    
}

contract testSuite {
   
    MatchMaker private target;
    StoreToken private token;
    function beforeAll () external {
        target = new MatchMaker();
        token = target.CurrencyProvider();
        token.tokenFaucet();
    }
    
    
    function testBuyUnit () external {
        testFunctions.testBuyUnit(target,token);
    }
    
    function testCreateAuction () external {
       testFunctions.testCreateAuction(target,token);
    }
    
    
    function testCreateSquad() external {
      testFunctions.testCreateSquad(target,token);
    }
    
    
}
