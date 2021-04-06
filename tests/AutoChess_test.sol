pragma solidity ^0.8.1;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "../MatchMaker_flat.sol";


contract testSuite {
   
    MatchMaker target;
    StoreToken token;
    function beforeAll () public {
        target = new MatchMaker();
        token = target.CurrencyProvider();
        token.tokenFaucet();
    }
    
    function testBuyUnit () public {
        uint256 initialBalance = token.balanceOf(address(this));
        uint256 initialUnits = target.balanceOf(address(this));
        target.buyUnit(IAutoChessBase.UnitType.Archer);
        target.buyUnit(IAutoChessBase.UnitType.Warrior);
        target.buyUnit(IAutoChessBase.UnitType.Cavalry, "short name");
        Assert.equal(target.balanceOf(address(this) ), 3 + initialUnits, "Units were not added");
        Assert.lesserThan(token.balanceOf(address(this)), initialBalance, "Money was not withdrawn");
    }
    
    function testCreateAuction () public {
       testBuyUnit();
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.startAuction(unitIds, 500);
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitIndexToState(unitIds[i])), uint8(IAutoChessBase.UnitState.Auctioning), "Incorrect Unit State");
       }
    }
    
    function testCreateSquadRandom() public{
       testBuyUnit();
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.randomChallenge(unitIds);
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitIndexToState(unitIds[i])), uint8(IAutoChessBase.UnitState.Deployed), "Incorrect Unit State");
       }
       Assert.greaterThan(target.getSquadIdsInTier(IAutoChessBase.DeploymentState.TierTwo).length, uint(1), "Squad wasn't added");
       Assert.equal(target.squadIndexToOwner(target.getSquadIdsInTier(IAutoChessBase.DeploymentState.TierTwo)[1]),address(this),"Squad owner wasn't updated");
    }
    
    function testCreateSquad() public {
       testBuyUnit();
       uint256[] memory unitIds = target.tokensOfOwner(address(this));
       target.targetedChallenge(unitIds,0);
       for(uint256 i; i < unitIds.length; i++){
           Assert.equal(uint8(target.unitIndexToState(unitIds[i])), uint8(IAutoChessBase.UnitState.Deployed), "Incorrect Unit State");
       }
       Assert.greaterThan(target.getSquadIdsInTier(IAutoChessBase.DeploymentState.TierTwo).length, uint(1), "Squad wasn't added");
       Assert.equal(target.squadIndexToOwner(target.getSquadIdsInTier(IAutoChessBase.DeploymentState.TierTwo)[1]),address(this),"Squad owner wasn't updated");
    }
}
