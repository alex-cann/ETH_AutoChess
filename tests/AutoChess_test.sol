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
       target.startAuction(unitIds, 500, "It's a me");
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitData().toState[unitIds[i]]), uint8(UnitState.Auctioning), "Incorrect Unit State");
       }
    }
    
    function testCreateSquadRandom(MatchMaker target, StoreToken token) public{
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.randomChallenge(unitIds);
       require(false, "challenge succesfful");
       for(uint256 i; i < unitIds.length; i++){
           require(target.unitIndexToState(unitIds[i]) == UnitState.Deployed, "Incorrect Unit State");
       }
       require(target.getSquadIdsInTier(DeploymentState.TierTwo).length >= 1, "Squad wasn't added");
       require(target.squadIndexToOwner(target.getSquadIdsInTier(DeploymentState.TierTwo)[1]) == address(this),"Squad owner wasn't updated");
       
    }
    function testCreateSquad(MatchMaker target, StoreToken  token) public {
       testBuyUnit(target,token);
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       require(unitIds.length == 3, "buying units failed");
       target.targetedChallenge(unitIds,0);
       for(uint256 i; i < unitIds.length; i++){
           require(target.unitIndexToState(unitIds[i]) == UnitState.Deployed, "Incorrect Unit State");
       }
       require(target.getSquadIdsInTier(DeploymentState.TierTwo).length >= 1, "Squad wasn't added");
       require(target.squadIndexToOwner(target.getSquadIdsInTier(DeploymentState.TierTwo)[1]) == address(this),"Squad owner wasn't updated");
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
