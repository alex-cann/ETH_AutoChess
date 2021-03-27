pragma solidity ^0.8.1; 

/// see CryptoKitties codebase here
/// https://ethfiddle.com/09YbyJRfiI and here https://medium.com/loom-network/how-to-code-your-own-cryptokitties-style-game-on-ethereum-7c8ac86a4eb3

//TODO make sure everything conforms to https://docs.soliditylang.org/en/v0.5.3/style-guide.html
interface IAutoChessBase{
    /*** TYPES AND MAPPINGS ***/
    //unit structs etc
    enum unitType { 
            archer, warrior
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
        unitType utype;
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
    
    //TODO replace Unit[] with unitids to reduce copying of data
    struct Squad{
        //list of the units in this squad
        uint256[] unitIds;
        //count of remaining units
        uint8 unitCount;
        //Tokens that will be returned when this squad returns
        uint16 stashedTokens;
        //tracks wether this unit is deployed
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
    
    Squad[] squads;
    mapping(DeploymentState => uint256[]) tierToSquadIndex;
    mapping(address => uint256[]) ownerToSquadIndex;
    
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
    
    
    mapping (uint256 => bool) unitIndexExists;
    
    // Predictable random number generator. Used for unit generation
    //the 
    //from https://fravoll.github.io/solidity-patterns/randomness.html
    function randomNumber(uint options) internal view returns (uint16) {
        return uint16(uint(blockhash(block.number - 1)) % options);
    }
}
