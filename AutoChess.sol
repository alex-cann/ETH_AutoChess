pragma solidity ^0.8.1; 

/// see CryptoKitties codebase here
/// https://ethfiddle.com/09YbyJRfiI and here https://medium.com/loom-network/how-to-code-your-own-cryptokitties-style-game-on-ethereum-7c8ac86a4eb3

///Note these have been marked as virtual for now
/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
abstract contract ERC721 {
    // Required methods
    function totalSupply() virtual public view returns (uint256 total);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) virtual external view returns (address owner);
    function approve(address _to, uint256 _tokenId) virtual external;
    function transfer(address _to, uint256 _tokenId) virtual external;
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) virtual external view returns (bool);
}


/// @title Interface for contracts conforming to ERC-20: Fungible Tokens
abstract contract ERC20 {
    // Required methods
   function totalSupply() virtual public view returns (uint256);
   function balanceOf(address _owner) virtual public view returns (uint256 balance);
   function transfer(address _to, uint256 _value) virtual public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
   function approve(address _spender, uint256 _value) virtual public returns (bool success);
   function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);
   
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // Optional
    //If you label the return values remix screams so I've omitted them
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) virtual external view returns (bool);
}



/// connects players and arranges for who plays what games
contract MatchMaker {
    
    
}


/// handles elo calculations
contract RankingEngine{
    
    
}


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
    mapping (address => uint256) public OwnerToUnitCount;
    
    ///@dev maps units to users allowed to call transferFrom
    mapping (uint256 => address) public UnitIndexToAllowed;
    
    mapping (uint256 => bool) unitIndexExists;
    
    //TODO may need another mapping to recreate destroyed units
}

///implementation based on https://medium.com/crypto-currently/the-anatomy-of-erc721-e9db77abfc24
/// Handles ERC771 implementation of units
contract UnitToken is AutoChessBase,ERC721{ 
    //TODO fill these in
    // Required methods
    
    //TODO remove hard coded value
    uint256 private totalUnits = 1000000000;
    
    
    function totalSupply() public view override returns (uint256 total){
        return totalUnits;
    }
    
    
    function balanceOf(address _owner) public view override returns (uint256 balance){
        return OwnerToUnitCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view override returns (address owner){
        //TODO set this check up later
        require(unitIndexExists[_tokenId]);
        return unitIndexToOwner[_tokenId];
    }
    
    function approve(address _to, uint256 _tokenId) public override{
        require (msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        //TODO set this check up later
        //allowed[msg.sender][_to] = _tokenId;
        Approval(msg.sender, _to, _tokenId);
    }
    
    
    function transfer(address _to, uint256 _tokenId) override public{
        require(unitIndexExists[_tokenId]);
        require (msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        //TODO Replace this so that address(0) is used for selling units to the contract
        require(_to != address(0));
        //Require that it is not in a squad (this could be changed to something smarter)
        //Example uses double map
        require(unitIndexToSquadIndex[_tokenId] == 0);
        
        OwnerToUnitCount[msg.sender]-=1;
        unitIndexToOwner[_tokenId] = _to;
        
        OwnerToUnitCount[_to]+=1;
        //Trigger the transfer Event
        Transfer(msg.sender,_to,_tokenId);
    }
    
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        require(unitIndexExists[_tokenId]);
        require(_from != _to);
        require(UnitIndexToAllowed[_tokenId] == _to);
        //Require that it is not in a squad (this could be changed to something smarter)
        //Example uses double map
        require(unitIndexToSquadIndex[_tokenId] == 0);
        
        OwnerToUnitCount[_from]-=1;
        unitIndexToOwner[_tokenId] = _to;
        
        OwnerToUnitCount[_to]+=1;
        //Trigger the transfer Event
        Transfer(msg.sender,_to,_tokenId);
        
    }

   

    // Optional
    function name() public view override returns (string memory) {
        return "AutoChess Unit Token";
    }
    
    function symbol() public view override returns (string memory) {
        return "ACHSS";
    }
    //TODO fill these in
    //function tokensOfOwner(address _owner) public view override returns (uint256[] memory tokenIds){}
    
    //function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) public view override returns (string memory infoUrl){}

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public view override returns (bool){
        
        
    }
}

///ERC20 token used to buy units from the store etc
contract StoreToken is ERC20 {
    
    //TODO fill these in
   function totalSupply() virtual public view returns (uint256);
   function balanceOf(address _owner) virtual public view returns (uint256 balance);
   function transfer(address _to, uint256 _value) virtual public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
   function approve(address _spender, uint256 _value) virtual public returns (bool success);
   function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);
   
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // Optional
    //function name() virtual public view returns (string name);
    //function symbol() virtual public view returns (string);
    function decimals() virtual public view returns (uint8);
    
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) virtual external view returns (bool);
}

/// handles the auctioning of units etc
contract UnitMarketplace {
    
    
}

/// handles the generation of new units
contract UnitMinter is UnitToken{
    
    
}


/// handles the game calculations and logic etc
contract GameEngine {
    
    
}

