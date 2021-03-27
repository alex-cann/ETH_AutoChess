pragma solidity ^0.8.1; 

/// see CryptoKitties codebase here
/// https://ethfiddle.com/09YbyJRfiI and here https://medium.com/loom-network/how-to-code-your-own-cryptokitties-style-game-on-ethereum-7c8ac86a4eb3

//TODO make sure everything conforms to https://docs.soliditylang.org/en/v0.5.3/style-guide.html

// has all the basic data etc
contract AutoChessBase {
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
    
    struct Squad{
        //list of the units in this squad
        Unit[] units;
        //count of remaining units
        uint8 unitCount;
        //Tokens that will be returned when this squad returns
        uint16 stashedTokens;
        //tracks wether this unit is deployed
        bool isDeployed;
        //timer for when the squad was deployed
        uint16 deployTime;
        //total ammount of atk, defense in the squad for making calculations easier
        uint16 totalAttack;
        uint16 totalDefence;
    }
    
    ///@dev global list of all units and squads. Maybe there is a better way
    Unit[] units;
    Squad[] squads;
    
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
    
    mapping (uint256 => bool) unitIndexExists;    
}
