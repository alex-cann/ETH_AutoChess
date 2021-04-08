pragma solidity ^0.8.1;
//SPDX-License-Identifier: UNLICENSED
//import "./tests/AutoChess_test.sol"; //TODO remove this once testing is done


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


contract StoreToken is ERC20 {
    //TODO support fancy bidding where you can approve more than you actually have

    uint256 private totalTokens = 1000000000;
    mapping (address => uint256) ownerToBalance;
    mapping (address => mapping(address => uint256)) ownerToApprovedWithdrawals;
    mapping (address => uint256) ownerToTotalApproved;
    address StoreAddress;

    constructor(address _owner) {
        //this contract is aware that the store owns it but not of the stores ABI
        StoreAddress = _owner;
        ownerToBalance[_owner] = totalTokens;
    }

    ///@dev functions only accessible from the marketplace (so coins can be autoApproved for auctions)
    modifier _storeOnly() {
        require(msg.sender == StoreAddress, "Only the StoreFront is allowed to use this.");
        _;
    }

    function totalSupply()  public view override returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return ownerToBalance[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(unApprovedBalanceOf(msg.sender) > _value, "Too few tokens are unlocked in your account!");
        ownerToBalance[msg.sender] -= _value;
        ownerToBalance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    ///@dev called by the store  when a user spends coin
    function spend(address _from, uint256 _value) public  _storeOnly returns (bool success){
        require(unApprovedBalanceOf(_from) > _value, "Too few tokens are unlocked in your account!");
        totalTokens-=_value;
        ownerToBalance[_from] -= _value;
        emit Transfer(_from, StoreAddress, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        //is this person authorized to withdraw this money
        require(ownerToApprovedWithdrawals[_from][_to] > _value, "Amount too large");
        ownerToApprovedWithdrawals[_from][_to] -= _value;
        ownerToTotalApproved[_from] -= _value;
        ownerToBalance[_from] -= _value;
        ownerToBalance[_to] += _value;
        return true;
    }
    ///@dev The amount of funds the user has minus any preapproved amounts
    function unApprovedBalanceOf(address _owner)  public view returns (uint256 remaining){
        return ownerToBalance[_owner] - ownerToTotalApproved[_owner];
    }
    
    //@dev A function for the store to preapprove transactions for a user
    function autoApprove(address _from, uint256 _value) public _storeOnly returns (bool success) {
        return _approve(_from, StoreAddress, _value);
    }

    //@dev A function for the store to unapprove transactions for other users
    function autoUnApprove(address _from, uint256 _value) public _storeOnly returns (bool success) {
        ownerToApprovedWithdrawals[_from][msg.sender] -= _value;
        ownerToTotalApproved[_from] -= _value;
        return true;
    }
    
    
    function _approve(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(unApprovedBalanceOf(_from) > _value, "Too few tokens are unlocked in your account");
        ownerToApprovedWithdrawals[_from][_to] += _value;
        ownerToTotalApproved[_from] += _value;
        emit Approval(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return _approve(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return ownerToApprovedWithdrawals[_owner][_spender];
    }
    
    
    function purchaseTokens() public payable{
        ownerToBalance[msg.sender]+= msg.value * 100;
    }
    
    function tokenFaucet() public{
        ownerToBalance[msg.sender]+= 100000;
    }
    
    function verifyTransaction(uint256 _value) public view returns(bool success){
        //TODO fill this in
        return true;
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


 /*** TYPES AND MAPPINGS ***/
enum UnitType { 
        Archer, Warrior, Cavalry
    }

struct Unit{
    uint16 power;
    uint16 defence;
    //functions as a multiplier on the other attributes
    uint16 level;
    //health of unit
    //represents max in storage, current in memory
    uint16 health;
    //what type of unit this is
    UnitType utype;
    //A name associated with this unit
    string name;
}

enum squadType {
    triangle, square, circle
}
//To check if a unit exists check if it's sate is dead
enum UnitState {
    Dead,Deployed,Auctioning,Default,Promised
}

enum DeploymentState{
    Unused,Retired,TierOne,TierTwo,TierThree,TierFour
}

struct Squad{
    //list of the units in this squad
    uint256[] unitIds;
    //Tokens that will be returned when this squad returns
    uint16 stashedTokens;
    //timer for when the squad was deployed
    uint16 deployTime;
}

struct Auction {
        uint256 highestBid;
        uint256[] assetIds;
        address highestBidder;
        address host;
        string name;
        //this seems like fun
        string highestBidText;
        //add some stuff for timeout
        uint256 endTime;
    }

struct UnitSet{
    Unit[] units;
    uint256[] unusedIds;
    mapping(uint256 => UnitState) toState;
    mapping(uint256 => address) toOwner;
    mapping(uint256 => address) toApproved;
    mapping(uint256 => uint256) toSquad;
}

struct SquadSet{
    Squad[] squads;
    uint256[] unusedIds;
    mapping(uint256 => address) toOwner;
    mapping(DeploymentState => uint256[]) fromTier;
    mapping(uint256 => DeploymentState) toState;
    mapping(address => uint256) toCount;
}



library UnitHelpers {
    
    function attack(Unit memory attacker, Unit memory defender) internal pure returns(bool){
        if(attacker.power < defender.defence){
            return false; //no damage dealt
        }
        uint16 dmg = attacker.power - defender.defence;
        if (defender.health <= dmg) {
            return true; // unit died
        }else{
            defender.health -= dmg;
            return false; //unit survived
        }
    }
    
    function getCost(UnitType _type) public pure returns(uint256 cost){
        if(_type == UnitType.Warrior){
            cost+=10;
        }else if(_type == UnitType.Archer){
            cost+=15;
        }else if(_type == UnitType.Cavalry){
            cost+=20;
        }else{
            require(false, "Not a valid unit type");
        }
        return cost;
    }
    
    function getCost(Unit storage unit) public view returns(uint256 cost){
        return getCost(unit.utype);
    }
    
    function getCost(UnitSet storage unitData, uint256 unitId) public view returns(uint256 cost){
        return getCost(unitData.units[unitId].utype);
    }
    
    function createUnit(UnitSet storage unitData, UnitType _type, string memory _name) public returns(uint256 newUnitId){
        
        Unit memory _unit = Unit({
                            power: 0,
                            defence: 0,
                            //functions as a multiplier on the other attributes
                            level: 1,
                            //starting health of unit
                            health: 0,
                            //what type of unit this is
                            utype: _type,
                            //A name associated with this unit
                            name: _name
                            });

        if (_type == UnitType.Archer) {
            // archer, high attack
            _unit.power += 15;
            _unit.defence += 1;
            _unit.health += 50;
        } else if (_type == UnitType.Warrior) {
            // warrior, high defence
            _unit.power += 10;
            _unit.defence += 5;
            _unit.health += 50;
        } else if (_type == UnitType.Cavalry){
            // cavalry, high health
            _unit.power += 10;
            _unit.defence += 1;
            _unit.health += 75;
        }
        if(unitData.unusedIds.length > 0){
            newUnitId = unitData.unusedIds[unitData.unusedIds.length -1];
            unitData.unusedIds.pop();
            unitData.units[newUnitId] = _unit;
        }else{
            unitData.units.push(_unit);
    		require(unitData.units.length > 0, "units should not be empty");
    		newUnitId = unitData.units.length  - 1;
        }
        unitData.toState[newUnitId] = UnitState.Default;
    }
    
    function killUnit(UnitSet storage unitData, uint256 unitId) public returns (uint256 value){
        require(unitData.toState[unitId] != UnitState.Dead, "unit is already dead");
        unitData.toState[unitId] = UnitState.Dead;
        value = getCost(unitData,unitId);
        unitData.unusedIds.push(unitData.units.length);
    }
    
}

library SquadHelpers {
    
    function getUnits(SquadSet storage squadData,uint256 squadId, UnitSet storage unitData) public view returns(Unit[] memory _units){
        _units= new Unit[](squadData.squads[squadId].unitIds.length);
        for(uint i=0; i < _units.length; i++){
            _units[i] = unitData.units[squadData.squads[squadId].unitIds[i]];
        }
    }
    
    function afterBattle(SquadSet storage squadData, UnitSet storage unitData, uint256 squadId, uint8 lastLiving) public returns (uint256 value){
        for(uint i=0; i < lastLiving; i++){
            unitData.toState[squadData.squads[squadId].unitIds[i]] = UnitState.Default;
        }
        
        for(uint i=lastLiving; i < squadData.squads[squadId].unitIds.length; i++){
            value += UnitHelpers.getCost(unitData,squadData.squads[squadId].unitIds[i]);
            unitData.toState[squadData.squads[squadId].unitIds[i]] = UnitState.Default;
            unitData.unusedIds.push(squadData.squads[squadId].unitIds[i]);
        }
    }
    
    function deleteSquad(SquadSet storage squadData, uint256 squadId) public returns(uint256 winnings){
        require(squadData.toState[squadId] == DeploymentState.Retired, "unit is already dead");
        delete squadData.toState[squadId];
        delete squadData.toOwner[squadId];
        winnings = squadData.squads[squadId].stashedTokens;
        delete squadData.squads[squadId];
        squadData.unusedIds.push(squadId);
    }
    
    function createSquad(SquadSet storage squadData, UnitSet storage unitData, uint256[] calldata unitIds, address _owner) public returns(uint256 squadId, DeploymentState tier){
        //TODO make sure that _unitIds is one of the correct lengths
        require(unitIds.length <= 7, "Invalid number of units");
        for(uint8 i=0; i < unitIds.length; i+=1){
            require(unitData.toOwner[unitIds[i]] == _owner, "You don't own this unit!");
            require(unitData.toState[unitIds[i]] == UnitState.Default, "Unit is busy");//check that this unit isn't doing something else
            unitData.toState[unitIds[i]] = UnitState.Deployed;
        }
        tier = AutoChessHelpers.getTier(unitIds.length);
        Squad memory _squad = Squad({
                    unitIds: new uint256[](0),
                    deployTime:uint16(block.timestamp), //TODO this seems sketch
                    stashedTokens:0
                    });
       
        
        if(squadData.unusedIds.length > 0){
            squadId = unitData.unusedIds[squadData.unusedIds.length - 1];
            delete squadData.unusedIds[squadData.unusedIds.length - 1];
            squadData.squads[squadId] = _squad;
        }else{
            squadData.squads.push(_squad);
    		require(unitData.units.length > 0, "units should not be empty");
    		squadId = squadData.squads.length  - 1;
        }
         squadData.toState[squadId] = tier;
        //TODO figure out a better way of making this work
        //https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb
         for(uint8 i=0; i < unitIds.length; i+=1){
            squadData.squads[squadId].unitIds.push(unitIds[i]);
        }
        squadData.toOwner[squadId] = _owner;
        squadData.fromTier[tier].push(squadId);
        squadData.toCount[_owner]+=1;
    }
    
}

library AutoChessHelpers {
    // Predictable random number generator. Used for unit generation
    //the 
    //from https://fravoll.github.io/solidity-patterns/randomness.html
    function randomNumber(uint options) public view returns (uint8) {
        //random is broken on remix
        //uncomment for depoyed environment
        //return uint8(uint(blockhash(block.number - 1)) % options);
        return 0;
    }
    
    function getTier(uint unitCount) public pure returns(DeploymentState state){
        if(unitCount == 1){
            state = DeploymentState.TierOne;
        }else if(unitCount == 3){
            state = DeploymentState.TierTwo;
        }else if(unitCount == 5){
            state = DeploymentState.TierThree;
        }else if(unitCount == 7){
            state = DeploymentState.TierFour;
        }
    }
}
//TODO some refactoring
library AuctionFunctions{
    
    function bid(Auction storage auction, uint256 _value, StoreToken currency) public {
        //check if this bid is big enough
        require(_value > auction.highestBid, "This is not a new highest bid!");
        require(auction.endTime <= block.timestamp, "It is too late to bid!");
        //preapprove the transaction to the Auction
        currency.autoApprove(address(this), _value);
        //remove hold on previous highest bidders currency
        currency.autoUnApprove(auction.highestBidder,auction.highestBid);
        auction.highestBid = _value;
        auction.highestBidder = msg.sender;
    }
    
    
    function claimAuction(Auction storage auction, StoreToken currency, ERC721 assetProvider) public {
        require(auction.endTime > block.timestamp, "It is too late to withdraw this auction!");
        //withdraw the highestbidders bid
        for (uint i=0; i < auction.assetIds.length; i++){
            assetProvider.transferFrom(auction.host,auction.highestBidder,auction.assetIds[i]);
            
        }
        currency.transferFrom(auction.highestBidder, auction.host, auction.highestBid);
    }
    
    function createAuction(Auction[] storage auctions, uint256[] calldata _assets, uint256 _asking, string calldata title) public returns(uint256 auctionId){
         auctions.push(Auction({
                        highestBid:_asking,
                        highestBidder: msg.sender,
                        host: msg.sender,
                        name: title,
                        assetIds: new uint256[](0),
                        highestBidText: "Default Bid",
                        endTime: block.timestamp + 1 hours
                        }));
        //transfer all the assets to the auctionhouse
        for(uint i =0; i < _assets.length; i++){
            auctions[auctions.length - 1].assetIds.push(_assets[i]);
        }
        return auctions.length-1;
    }
    
}

// has all the basic data etc
contract AutoChessBase{
    
    using SquadHelpers for SquadSet;
    using UnitHelpers for UnitSet;
    ///@dev global list of all units and squads. Maybe there is a better way
    UnitSet unitData;

    SquadSet squadData;
    
    mapping(address => uint256) ownerToUnitCount;
}

// File: UnitToken.sol



///implementation based on https://medium.com/crypto-currently/the-anatomy-of-erc721-e9db77abfc24
/// Handles ERC771 implementation of units


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
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract UnitToken is AutoChessBase, ERC721{
    //TODO fill these in
    // Required methods

    //TODO remove hard coded value
    uint256 private totalUnits = 1000000000;

    modifier _validTx(address _from, address _to, uint256 _tokenId){
        require(_from == ownerOf(_tokenId),"You don't own this unit");
        require(_from != _to, "You already own this unit");
        require(unitData.toState[_tokenId] == UnitState.Default, "Unit is unavailable");
        require(_to != address(0), "Not a valid address. Sorry!");
        _;
    }
    
    function totalSupply() public view override returns (uint256 total) {
        return totalUnits;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        for(uint i=0; i < unitData.units.length;i++){
           if(unitData.toOwner[i] == _owner){
               balance++;
           }
       }
    }

    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        owner = unitData.toOwner[_tokenId];
    }
    
    function approve(address _to, uint256 _tokenId) public _validTx(msg.sender,_to, _tokenId) override {
        unitData.toApproved[_tokenId] = _to;
        unitData.toState[_tokenId] = UnitState.Promised;
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(unitData.toState[_tokenId] == UnitState.Default, "Unit is busy");
        require(unitData.toOwner[_tokenId] == _from, "Unit is busy");
        unitData.toOwner[_tokenId] = _to;
        delete unitData.toApproved[_tokenId];
        //the contract calling this is the unit generator
        //Trigger the transfer Event
        emit Transfer(_from,_to,_tokenId);
    }


    function transfer(address _to, uint256 _tokenId) public _validTx(msg.sender,_to, _tokenId) override {
        _transfer(msg.sender,_to,_tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public _validTx(_from,_to,_tokenId) override {
        require(unitData.toApproved[_tokenId] == _to, "Unit is not promised to that user");
        //Require that it is not in a squad (this could be changed to something smarter)
        //Example uses double map
        _transfer(_from,_to,_tokenId);
    }


    // Optional
    function name() public override pure returns (string memory) {
        return "AutoChess Unit Token";
    }

    function symbol() public override pure returns (string memory) {
        return "ACHSSU";
    }

    
    function tokensOfOwner(address _owner) public view override returns (uint256[] memory tokenIds){
        uint256 count;
        tokenIds = new uint256[](ownerToUnitCount[_owner]);
        for(uint i=0; i < unitData.units.length;i++){
           if(unitData.toOwner[i] == _owner){
            tokenIds[count++] = i;
           }
        }
    }

    function getToken(uint256 tokenId) public view returns(Unit memory unit){
        return unitData.units[tokenId];
    }
    
    function getUnitState(uint256 unitId) public view returns(UnitState state){
        return unitData.toState[unitId];
    }
    //function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) public view override returns (string memory infoUrl){}

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public view override returns (bool) {

    }
}	

// File: UnitMarketplace.sol


interface IUnitMarketplace{
    
    function bid(uint256 _auctionId, uint256 _value) external;
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) external;
    function startAuction(uint256[] calldata _assets, uint256 _asking,string calldata title) external returns(uint256 auctionId);
    function withdrawAuction(uint256 _auctionId) external returns(bool success);
}


contract UnitMarketplace is UnitToken,IUnitMarketplace {
    //objects:
    using AuctionFunctions for Auction;
    
    address public ProviderAddress;
    StoreToken public CurrencyProvider;
    
    //A list of all ongoing auctions
    Auction[] public _auctions;

    constructor() {
        CurrencyProvider = new StoreToken(address(this));
        ProviderAddress = address(CurrencyProvider);
    }

    function bid(uint256 _auctionId, uint256 _value) public override {
       _auctions[_auctionId].bid(_value, CurrencyProvider);
    }

    /// So people can bid with a message etc
    /// just for funzies
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) public override {
        _auctions[_auctionId].bid(_value, CurrencyProvider);
        _auctions[_auctionId].highestBidText = _msg;
    }

    function auctionApprove(address _from, uint256 _tokenId) internal {
        require(_from == ownerOf(_tokenId),"You don't own this unit");
        require(unitData.toState[_tokenId] == UnitState.Default, "Unit is unavailable");
        require(_from != address(0));
        unitData.toApproved[_tokenId] = _from;
        unitData.toState[_tokenId] = UnitState.Auctioning;
    }

    function startAuction(uint256[] calldata _assets, uint256 _asking, string calldata title) external override returns(uint256 auctionId) {
        //transfer all the assets to the auctionhouse
        for(uint i =0; i < _assets.length; i++){
            auctionApprove(msg.sender,_assets[i]);
        }
        auctionId = AuctionFunctions.createAuction(_auctions, _assets, _asking, title);
    }

    function withdrawAuction(uint256 _auctionId) public override returns(bool success){
        require(_auctions[_auctionId].host == msg.sender, "You are not the host of this auction!");
        require(_auctions[_auctionId].endTime > block.timestamp, "It is too late to withdraw this auction!");
        //withdraw the highestbidders bid
        CurrencyProvider.autoUnApprove(_auctions[_auctionId].highestBidder,_auctions[_auctionId].highestBid);
        //TODO reset ownership of units back to the host or use approval system instead
        return true;
    }

    function getAssetIds(uint256 _auctionId) public view returns(uint256[] memory assetIds){
        assetIds = _auctions[_auctionId].assetIds;
    }

    function getAuctionCount() public view returns(uint256 count){
        return _auctions.length;
    }

    //TODO add reverse auctions where someone offers tokens. Maybe?
}

// File: SquadBuilder.sol



interface ISquadBuilder is IUnitMarketplace{
    function buyUnit(UnitType _type) external returns (uint256);
    function buyUnit(UnitType _type, string memory _name) external returns (uint256);
    event UnitCreated(address owner, uint256 indexed id);
    event SquadCreated(address owner, uint256 _id);
}

contract SquadBuilder is UnitMarketplace, ISquadBuilder {

    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    string constant DEFAULT_NAME = "Maurice, the Mediocre";
    uint256[] unusedUnitIds;
    uint256[] unusedSquadIds;
    /// @dev creates and stores a new unit
    using SquadHelpers for SquadSet;
    using SquadHelpers for uint8;
    using UnitHelpers for Unit;
    using UnitHelpers for UnitType;
    
    constructor() UnitMarketplace(){}
    
    
    function _buyUnit(address _owner, UnitType _type, string memory _name) internal returns (uint256 _unitId){
        uint256 _cost = _type.getCost();
        CurrencyProvider.spend(_owner,_cost);
        _unitId = UnitHelpers.createUnit(unitData, _type, _name);
        emit UnitCreated(_owner,_unitId);
        unitData.toOwner[_unitId] = _owner;
        ownerToUnitCount[_owner]+=1;
    }
    
    function buyUnit(UnitType _type) public override returns (uint256){
        return _buyUnit(msg.sender, _type, DEFAULT_NAME);
    }
    
    function buyUnit(UnitType _type, string calldata _name) public override returns (uint256){
        return _buyUnit(msg.sender,_type,_name);
    }
    
    
    // create squad
    function _createSquad(address _owner, uint256[] memory _unitIds) internal returns(uint256 squadId, DeploymentState tier){
        (squadId,tier) = squadData.createSquad(unitData,_unitIds,_owner);
    }
    
   
    
}

// File: GameEngine.sol

/// handles the game calculations and logic etc


interface IGameEngine is ISquadBuilder{
    //TODO add events here
}

/// Handles the actual playing of the game
contract GameEngine is SquadBuilder, IGameEngine{

    constructor() SquadBuilder(){}
    using UnitHelpers for Unit;
    using SquadHelpers for Squad;
    using SquadHelpers for SquadSet;
    
    function _squadBattle(uint attackerSquadId, uint defenderSquadId) internal returns(uint winnings) {
        require(squadData.toState[attackerSquadId] == squadData.toState[defenderSquadId], "wrong tier");
        
        //Making these storage variables is very dubious
       
        Unit[] memory atkUnits = squadData.getUnits(attackerSquadId,unitData);
        Unit[] memory dfdUnits = squadData.getUnits(defenderSquadId,unitData);
        
        uint8 atkNum = uint8(atkUnits.length);
        uint8 dfdNum = uint8(dfdUnits.length);
        require(atkNum == dfdNum, "inequal sizes");
        
        //TODO include more details wrt squad formation
        //     also include formation in the Squad structure
        uint atkId;
        uint dfdId;
        bool turn = true;
        //Hard cap on the number of rounds for gas reasons
        for(uint i=0; i < 2 && atkNum > 0 && dfdNum > 0;i++) {
            if(turn){
                //challenger is attacking
                atkId = AutoChessHelpers.randomNumber(atkNum);
                dfdId = dfdNum - 1;
                require(atkId < atkUnits.length, "Invalid aa choice");
                require(dfdId < dfdUnits.length, "Invalid dd choice");
                
                // attack happens
                if(atkUnits[atkId].attack(dfdUnits[dfdId])){
                    dfdNum--;
                }
                
            }else{
                //defender is attacking
                atkId = AutoChessHelpers.randomNumber(dfdNum);
                dfdId = atkNum - 1;
                require(atkId < atkUnits.length, "Invalid da choice");
                require(dfdId < atkUnits.length, "Invalid ad choice");
                
                // attack happens
                if(dfdUnits[atkId].attack(atkUnits[dfdId])){
                    atkNum--;   
                }
            }
            turn = !turn;
        }
        
        // copy defender squad units state back to chain
        squadData.afterBattle(unitData, defenderSquadId, dfdNum);
        
        //TODO finish updating defender state
        squadData.toState[defenderSquadId] = DeploymentState.Retired;
        //Uncomment this when unitCount is up and running
        //defender.unitCount = dfdNum;
        // TODO should squad be retired if all died

        if (atkNum == 0) {
            // attacker lost the battle
            return 0;
        } else {
            // calculate winnings here
            // for now returning static value of 10
            return 10;
        }
    }
    
    
}

// File: MatchMaker.sol

/// connects players and arranges for who plays what games

///handles all the adding of units and whatnot

interface IMatchMaker is IGameEngine{
    
    function randomChallenge(uint256[] calldata unitIds) external returns (uint256 squadId);
    function targetedChallenge(uint256[] calldata unitIds, uint256 _targetId) external returns (uint256 squadId);
    function withdrawSquad(uint256 _squadId) external returns (bool success);
    function getSquadIdsInTier(DeploymentState _tier) external view returns (uint256[] memory deployed); //This is subject to change
    
}


contract MatchMaker is GameEngine, IMatchMaker{
    
    /// Calls the parent constructor
    constructor() GameEngine(){
        //Generate enough units to fill each tier
        uint256[] memory _ids7 = new uint256[](7);
        uint256[] memory _ids5 = new uint256[](5);
        uint256[] memory _ids3 = new uint256[](3);
        uint256[] memory _ids1 = new uint256[](1);
        for(uint i=0; i < 7;i+=1){
            _ids7[i] = _buyUnit(address(this),UnitType.Cavalry,"DEFAULT");
        }
        
        for(uint i=0; i < 5;i+=1){
            _ids5[i] = _buyUnit(address(this),UnitType.Cavalry,"DEFAULT");
        }
        for(uint i=0; i < 3;i+=1){
            _ids3[i] = _buyUnit(address(this),UnitType.Cavalry,"DEFAULT");
        }
        for(uint i=0; i < 1;i+=1){
            _ids1[i] = _buyUnit(address(this),UnitType.Cavalry,"DEFAULT");
        }
        
        require(unitData.units.length<=16,"too many units created");
        //TODO figure out why this fixes things
        require(ownerToUnitCount[address(this)] <= 16, "hmmm");
        //make all the units into a squad
        _createSquad(address(this), _ids7);
        _createSquad(address(this), _ids5);
        _createSquad(address(this), _ids3);
        _createSquad(address(this), _ids1);
   }
   
    //TODO figure out why this doesn't work but targeted does
    function randomChallenge(uint256[] calldata _unitIds) public override returns (uint256 squadId){
        DeploymentState tier;
        uint256 targetId = AutoChessHelpers.randomNumber(squadData.fromTier[tier].length);
        (squadId, tier) = _createSquad(msg.sender, _unitIds);
        _squadBattle(squadId,squadData.fromTier[tier][targetId]);
        squadData.toState[squadData.fromTier[tier][targetId]] = DeploymentState.Retired;
        squadData.toState[squadData.fromTier[tier][targetId]];
    }


    function targetedChallenge(uint256[] calldata _unitIds, uint256 targetId) public override returns (uint256 squadId){
        
        DeploymentState tier;
        (squadId, tier) = _createSquad(msg.sender,_unitIds);
        //make sure it's a valid target
        require(squadData.fromTier[tier].length > targetId, "Invalid unit ID");
        require(squadId != targetId, "unit can't fight itself");
        _squadBattle(squadId,squadData.fromTier[tier][targetId]);
    }


    function getSquadIdsInTier(DeploymentState _tier) public override view returns (uint256[] memory){
        return squadData.fromTier[_tier];
    }
    
    function squadsOf(address _owner) public view returns (uint256[] memory squadIds){
       uint256 count;
        squadIds = new uint256[](squadData.toCount[_owner]);
        for(uint i=0; i < unitData.units.length;i++){
           if(unitData.toOwner[i] == _owner){
            squadIds[count++] = i;
           }
        }
    }
    
    function squadCount(address _owner) public view returns(uint256){
        return squadData.toCount[_owner];
    }
    
    function collectSquad(uint256 _squadId) public{
        //remove the squad from the tier
        
    }
    
    function getSquadUnitIds(uint256 squadId) public view returns (uint256[] memory){
        return squadData.squads[squadId].unitIds;
    }
    
    function getSquads() public view returns (Squad[] memory){
        return squadData.squads;
    }
    
    function getSquad(uint256 squadId) public view returns (Squad memory){
        return squadData.squads[squadId];
    }
    
    function withdrawSquad(uint256 _squadId) public override returns (bool success){
        
    }
    
    
}
