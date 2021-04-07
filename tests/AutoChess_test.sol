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
        Assert.equal(target.balanceOf(address(this) ), 3 + initialUnits, "Units were not added");
        Assert.lesserThan(token.balanceOf(address(this)), initialBalance, "Money was not withdrawn");
    }
    
    function testCreateAuction (MatchMaker target, StoreToken token) public {
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.startAuction(unitIds, 500);
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitIndexToState(unitIds[i])), uint8(UnitState.Auctioning), "Incorrect Unit State");
       }
    }
    
    function testCreateSquadRandom(MatchMaker target, StoreToken token) public{
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.randomChallenge(unitIds);
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitIndexToState(unitIds[i])), uint8(UnitState.Deployed), "Incorrect Unit State");
       }
       Assert.greaterThan(target.getSquadIdsInTier(DeploymentState.TierTwo).length, uint(1), "Squad wasn't added");
       Assert.equal(target.squadIndexToOwner(target.getSquadIdsInTier(DeploymentState.TierTwo)[1]),address(this),"Squad owner wasn't updated");
    }
    
    function testCreateSquad(MatchMaker target, StoreToken  token) public {
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.targetedChallenge(unitIds,0);
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitIndexToState(unitIds[i])), uint8(UnitState.Deployed), "Incorrect Unit State");
       }
       Assert.greaterThan(target.getSquadIdsInTier(DeploymentState.TierTwo).length, uint(1), "Squad wasn't added");
       Assert.equal(target.squadIndexToOwner(target.getSquadIdsInTier(DeploymentState.TierTwo)[1]),address(this),"Squad owner wasn't updated");
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
    
    function testCreateSquadRandom() external{
       testFunctions.testCreateSquadRandom(target,token);
    }
    
    function testCreateSquad() external {
      testFunctions.testCreateSquad(target,token);
        
    }
}
