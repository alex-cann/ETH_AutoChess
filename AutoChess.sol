pragma solidity ^0.8.1; 

/// see CryptoKitties codebase here
/// https://ethfiddle.com/09YbyJRfiI and here https://medium.com/loom-network/how-to-code-your-own-cryptokitties-style-game-on-ethereum-7c8ac86a4eb3

//TODO make sure everything conforms to https://docs.soliditylang.org/en/v0.5.3/style-guide.html
interface IAutoChessBase{
    /*** TYPES AND MAPPINGS ***/
    //unit structs etc
    //Made these capitals so that ENUMS are consistently styled
    enum UnitType { 
        Archer, Warrior, Cavalry
    }

    struct Unit{
        uint16 attack;
        uint16 defence;
        //functions as a multiplier on the other attributes
        uint16 level;
        //starting health of unit
        uint16 maxHealth;
        // health remaining on this unit
        uint16 curHealth;
        //what type of unit this is
        UnitType utype;
        //A name associated with this unit
        string name;
    }

    enum squadType {
        triangle, square, circle
    }

    enum UnitState {
        Deployed,Dead,Auctioning,Default,Promised
    }

    enum DeploymentState{
        Retired,TierOne,TierTwo,TierThree,TierFour
    }

    
    struct Squad{
        //list of the units in this squad
        uint256[] unitIds;
        //count of remaining units
        uint8 unitCount;
        //Tokens that will be returned when this squad returns
        uint16 stashedTokens;
        //tracks wether this squad is deployed
        DeploymentState state;
        //timer for when the squad was deployed
        uint16 deployTime;
        //total ammount of atk, defense in the squad for making calculations easier
        uint16 totalAttack;
    }

    
   
    
}
// has all the basic data etc
contract AutoChessBase is IAutoChessBase {

    ///@dev global list of all units and squads. Maybe there is a better way
    Unit[] units;

    Squad[] public squads;
    ///@dev lists of squads in each deployment tier/state
    /// This could be removed and replaced with a lot of if statements
    mapping(DeploymentState => uint256[]) tierToSquadIndex;
    
    ///@dev maps each owner to their squad indices
    /// used for allowing a user to view their squads
    mapping(address => uint256[]) ownerToSquadIndex;


    //TODO  Is used for determining if a unit is in a squad should be able to 
    //get rid of this with some careful coding
    ///@dev maps the index of each unit to their squad
    mapping (uint256 => uint256) public unitIndexToSquadIndex;

    ///@dev says who owns each unit
    mapping (uint256 => address) public unitIndexToOwner;

    ///@dev maps squads to the owner used to cash in a squad
    mapping (uint256 => address) public squadIndexToOwner;

    ///@dev maps owners to their count of units
    mapping (address => uint256) public ownerToUnitCount;

    ///@dev maps units to users allowed to call transferFrom
    mapping (uint256 => address) public unitIndexToAllowed;

    ///@dev maps to the state of the unit for easy access
    mapping (uint256 => UnitState) public unitIndexToState;

    mapping (address => uint256[]) public ownerToUnitIndices;
    
    
    //TODO check if this is necessary since units can't be destroyed anymore
    mapping (uint256 => bool) unitIndexExists;
    
    // Predictable random number generator. Used for unit generation
    //the 
    //from https://fravoll.github.io/solidity-patterns/randomness.html
    function randomNumber(uint options) internal view returns (uint16) {
        return uint16(uint(blockhash(block.number - 1)) % options);
    }
    
    //TODO add constants for TIER sizes
    //TODO add constants for DEFAULT STATS

    // TODO consider using enum directly instead of this function
    //      not sure if solidity supports it
    //      for now using this function
    function _getTier(uint _unitCount) internal pure returns(DeploymentState state){
        if(_unitCount == 2){
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

}
