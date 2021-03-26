pragma solidity ^0.8.1; 

/// see CryptoKitties codebase here
/// https://ethfiddle.com/09YbyJRfiI and here https://medium.com/loom-network/how-to-code-your-own-cryptokitties-style-game-on-ethereum-7c8ac86a4eb3

///Note these have been marked as virtual for now
/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
interface ERC721 {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId)  external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() external  view returns (string memory);
    function symbol() external view returns (string memory);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


/// @title Interface for contracts conforming to ERC-20: Fungible Tokens
interface ERC20 {
    // Required methods
   function totalSupply() external view returns (uint256);
   function balanceOf(address _owner) external view returns (uint256 balance);
   function transfer(address _to, uint256 _value) external returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
   function approve(address _spender, uint256 _value) external returns (bool success);
   function allowance(address _owner, address _spender) external view returns (uint256 remaining);
   
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // Optional
    //If you label the return values remix screams so I've omitted them
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    //function decimals() external view returns (uint8);
    
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
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
    mapping (address => uint256) public ownerToUnitCount;
    
    ///@dev maps units to users allowed to call transferFrom
    mapping (uint256 => address) public unitIndexToAllowed;
    
    mapping (uint256 => bool) unitIndexExists;
    
    
    
}

///implementation based on https://medium.com/crypto-currently/the-anatomy-of-erc721-e9db77abfc24
/// Handles ERC771 implementation of units
contract UnitToken is AutoChessBase, ERC721{ 
    //TODO fill these in
    // Required methods
    
    //TODO remove hard coded value
    uint256 private totalUnits = 1000000000;
    
    
    function totalSupply() public view override returns (uint256 total){
        return totalUnits;
    }
    
    
    function balanceOf(address _owner) public view override returns (uint256 balance){
        return ownerToUnitCount[_owner];
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
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal{
        ownerToUnitCount[_from]-=1;
        unitIndexToOwner[_tokenId] = _to;
        //remove any allowances on transfering this unit
        delete unitIndexToAllowed[_tokenId];
        //TODO remove this unit from squads
        ownerToUnitCount[_to]+=1;
        //the contract calling this is the unit generator
        //Trigger the transfer Event
        emit Transfer(_from,_to,_tokenId);
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
        
        _transfer(msg.sender,_to,_tokenId);
    }
    
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        require(unitIndexExists[_tokenId]);
        require(_from != _to);
        require(unitIndexToAllowed[_tokenId] == _to);
        //Require that it is not in a squad (this could be changed to something smarter)
        //Example uses double map
        require(unitIndexToSquadIndex[_tokenId] == 0);
        
        _transfer(_from,_to,_tokenId);
    }

   
    // Optional
    function name() public override pure returns (string memory) {
        return "AutoChess Unit Token";
    }
    
    function symbol() public override pure returns (string memory) {
        return "ACHSSU";
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
    //TODO support fancy bidding where you can approve more than you actually have
    
    
    uint256 private totalTokens = 1000000000;
    mapping (address => uint256) ownerToBalance;
    mapping (address => mapping(address => uint256)) ownerToApprovedWithdrawals;
    mapping (address => uint256) ownerToTotalApproved;
    address StoreAddress;
    constructor(){
        //this contract is aware that the store owns it but not of the stores ABI
        StoreAddress = msg.sender;
    }
    
    ///@dev functions only accessible from the marketplace (so coins can be autoApproved for auctions)
    modifier _storeOnly(){
        assert(msg.sender == StoreAddress);
        _;
    }
    
    function totalSupply()  public view override returns (uint256){
       return totalTokens;
    }
   
   function balanceOf(address _owner) public view override returns (uint256 balance){
       return ownerToBalance[_owner];
   }
   
   function transfer(address _to, uint256 _value) public override returns (bool success){
       assert(balanceOf(msg.sender) > _value);
       ownerToBalance[msg.sender]-=_value;
       //TODO check for edge cases
       ownerToBalance[_to]+=_value;
       emit Transfer(msg.sender, _to,  _value);
       return true;
   }
   
   function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
       //is this person authorized to withdraw this money
       assert(ownerToApprovedWithdrawals[_from][_to] > _value);
       assert(ownerToBalance[_from] > _value);
       
       ownerToApprovedWithdrawals[_from][_to]-=_value;
       ownerToTotalApproved[_from]-=_value;
       ownerToBalance[_from]-=_value;
       ownerToBalance[_to]+=_value;
       return true;
   }
   
   function autoApprove(address _from, uint256 _value) public _storeOnly returns (bool success){
       return _approve(_from,StoreAddress,_value);
   }
   
   function _approve(address _from, address _to, uint256 _value) internal returns (bool success){
       assert(ownerToBalance[_from] > (_value + ownerToTotalApproved[msg.sender]));
       ownerToApprovedWithdrawals[_from][_to]+=_value;
       ownerToTotalApproved[_from]+=_value;
       return true;
   }
   
   function approve(address _spender, uint256 _value) public override returns (bool success){
      return _approve(msg.sender, _spender, _value);
   }
   
   function allowance(address _owner, address _spender) public override view returns (uint256 remaining){
       return ownerToApprovedWithdrawals[_owner][_spender];
   }
   
    
    // Optional
    function name() public override pure returns (string memory){
        return "AutoChess Store Token";
    }
    function symbol() public override pure returns (string memory){
        return "ACHSST";
    }
    //function decimals() virtual public view returns (uint8);
    
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public override view returns (bool){
        //TODO this is not the way to be
        return true;
    }
}

/// handles the auctioning of units etc
//TODO add autobidding ()
contract UnitMarketplace is UnitToken{
    //objects:
    //Owns the token contract 
    // functions:
    // list unit for auction
    // view current Auctions
    // bid on auction
    
    struct Auction {
        uint256 highestBid;
        uint256[] assetIds;
        address highestBidder;
        address host;
        string name;
        //this seems like fun
        string highestBidText;
        //add some stuff for timeout
    }
    address ProviderAddress;
    StoreToken CurrencyProvider;
    
    //A list of all ongoing auctions
    Auction[] _auctions;
    
    
    constructor(){
        CurrencyProvider = new StoreToken();
        ProviderAddress = address(CurrencyProvider);
    }
    
    function bid(uint256 _auctionId, uint256 _value) public returns(bool success){
        Auction memory auction = _auctions[_auctionId];
        //check if this bid is big enough
        assert(_value > auction.highestBid);
        //preapprove the transaction to the Auction
        assert(CurrencyProvider.autoApprove(msg.sender, _value));
        auction.highestBid = _value;
        auction.highestBidder = msg.sender;
        return true;
    }
    /// So people can bid with a message etc
    /// just for funzies
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) public returns(bool success){
        assert(bid(_auctionId,_value));
        _auctions[_auctionId].highestBidText = _msg;
        return true;
    }
    
    function startAuction(uint256[] calldata _assets, uint256 _asking) public returns(bool success){
        //TODO verify that all the units up for auction aren't in a squad etc
       _auctions.push(Auction({
            highestBid:_asking,
            highestBidder: msg.sender,
            host: msg.sender,
            name: "PLACEHOLDER",
            assetIds: _assets,
            highestBidText: "Default Bid"
        }));
        //transfer all the assets to the auctionhouse
        for(uint i =0; i < _assets.length; i++){
            _transfer(msg.sender,address(this),_assets[i]);
        }
        //TODO add an auction event
        return true;
    }
    //TODO add reverse auctions where someone offers tokens
    
    
    
}

/// handles the generation of new units
contract UnitMinter is UnitToken{
    
    
    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    uint256[] unusedIndices;
    
    // Predictable random number generator. Used for unit generation
    //the 
    //from https://fravoll.github.io/solidity-patterns/randomness.html
    function randomNumber(uint options) internal view returns (uint16) {
        return uint16(uint(blockhash(block.number - 1)) % options);
    }

    
    /// @dev creates and stores a new unit
    function _generateUnit() internal returns (uint)
    {
        //TODO make this dependent on unit type and less silly
        Unit memory _unit = Unit({
            attack: 5 + randomNumber(2),
            defence: 5 + randomNumber(2),
            //functions as a multiplier on the other attributes
            level: 1,
            //starting health of unit
            maxHealth: 5 + randomNumber(2),
            // health remaining on this unit
            curHealth: 5 + randomNumber(2),
            //what type of unit this is
            utype: unitType(randomNumber(2)),
            //A name associated with this unit
            name: "default unit name"
        });
        uint256 newUnitId;
        if(unusedIndices.length == 0){
            units.push(_unit);
            newUnitId = units.length  - 1;
        }else{
            //get the latest unused Index
            newUnitId = unusedIndices[unusedIndices.length - 1];
            //delete from the list of unused Indices since it is now used
            unusedIndices.pop();
        }
        
        
        //TODO change how this works. Maybe via auction
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        unitIndexToOwner[newUnitId] = address(this);
        
        return newUnitId;
    }
    
}


/// handles the game calculations and logic etc
contract GameEngine {
    
    
}




