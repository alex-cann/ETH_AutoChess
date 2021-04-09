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
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract StoreToken is ERC20 {
    //TODO support fancy bidding where you can approve more than you actually have

    uint256 private totalTokens = 1000000000;
    mapping (address => uint256) private ownerToBalance;
    mapping (address => mapping(address => uint256)) private ownerToApprovedWithdrawals;
    mapping (address => uint256) private ownerToTotalApproved;
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
    function deposit(address _to, uint256 _value) public _storeOnly returns (bool success) {
        totalTokens+=_value;
        ownerToBalance[_to] += _value;
        emit Transfer(StoreAddress, _to, _value);
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
    
    
    // Optional
    function name() public override pure returns (string memory){
        return "AutoChess Store Token";
    }
    function symbol() public override pure returns (string memory){
        return "ACHSST";
    }
    //function decimals() virtual public view returns (uint8);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    //function supportsInterface(bytes4 _interfaceID) public override view returns (bool){return true;}
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
    uint256[] unusedIds;
    Unit[] units;
    mapping(uint256 => UnitState) toState;
    mapping(uint256 => address) toOwner;
    mapping(uint256 => address) toApproved;
    mapping(uint256 => uint256) toSquad;
    mapping(address => uint256) toCount;
}

struct SquadSet{
    uint256[] unusedIds;
    Squad[] squads;
    mapping(uint256 => address) toOwner;
    mapping(uint256 => DeploymentState) toState;
    mapping(address => uint256) toCount;
    mapping(DeploymentState => uint256) toTierSize;
}

struct AuctionSet{
    Auction[] auctions;
    uint256[] unusedIds;
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
    
    function getCost(UnitType _type) public pure returns(uint16 cost){
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
    
    function getCost(Unit storage unit) internal view returns(uint16 cost){
        return getCost(unit.utype);
    }
    
    function getCost(UnitSet storage unitData, uint256 unitId) internal view returns(uint16 cost){
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
        newUnitId = add(unitData,_unit);
    }
    
    function killUnit(UnitSet storage unitData, uint256 unitId) public returns (uint256 value){
        require(unitData.toState[unitId] != UnitState.Dead, "unit is already dead");
        unitData.toState[unitId] = UnitState.Dead;
        value = getCost(unitData,unitId);
        unitData.unusedIds.push(unitId);
    }
    
    function transfer(UnitSet storage unitData, address _from, address _to, uint256 unitId) public{
        unitData.toOwner[unitId] = _to;
        delete unitData.toApproved[unitId];
        unitData.toCount[_from]--;
        unitData.toCount[_to]++;
        unitData.toState[unitId] = UnitState.Default;
    }
    
    function add(UnitSet storage data, Unit memory _unit) internal returns (uint256 newId){
        if(data.unusedIds.length > 0){
            newId = data.unusedIds[data.unusedIds.length -1];
            data.unusedIds.pop();
            data.units[newId] = _unit;
        }else{
            data.units.push(_unit);
    		newId = data.units.length  - 1;
        }
        data.toState[newId] = UnitState.Default;
    }
    
    function remove(UnitSet storage data, uint256 id) internal{
        data.unusedIds.push(id);
        data.toState[id] = UnitState.Dead;
    }
    
    function get(UnitSet storage data, uint256 id) internal view returns(Unit storage){
        return data.units[id];
    }
    
}

library SquadHelpers {
    
    function getUnits(SquadSet storage squadData,uint256 squadId, UnitSet storage unitData) public view returns(Unit[] memory _units){
        _units= new Unit[](squadData.squads[squadId].unitIds.length);
        for(uint i=0; i < _units.length; i++){
            _units[i] = unitData.units[squadData.squads[squadId].unitIds[i]];
        }
    }
    
    function afterBattle(SquadSet storage squadData, UnitSet storage unitData, uint256 squadId, uint8 lastLiving) public returns (uint16){
        for(uint i=0; i < lastLiving; i++){
            unitData.toState[getUnit(squadData,squadId,i)] = UnitState.Default;
        }
        uint16 recovered;
        for(uint i=lastLiving; i < squadData.squads[squadId].unitIds.length; i++){
            recovered += UnitHelpers.getCost(unitData,getUnit(squadData,squadId,i));
            unitData.toState[getUnit(squadData,squadId,i)] = UnitState.Default;
            unitData.unusedIds.push(getUnit(squadData,squadId,i));
        }
       squadData.toState[squadId] = DeploymentState.Unused;
       squadData.toTierSize[squadData.toState[squadId]]--;
       get(squadData,squadId).stashedTokens+=recovered * 4/10;
       return recovered * 6/10;
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
       
        squadId = add(squadData,_squad);
        
        squadData.toState[squadId] = tier;
        //https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb
         for(uint8 i=0; i < unitIds.length; i+=1){
            squadData.squads[squadId].unitIds.push(unitIds[i]);
        }
        squadData.toOwner[squadId] = _owner;
        squadData.toTierSize[tier]++;
        squadData.toCount[_owner]+=1;
    }
    
    function add(SquadSet storage data, Squad memory _squad) internal returns (uint256 newId){
        if(data.unusedIds.length > 0){
            newId = data.unusedIds[data.unusedIds.length -1];
            data.unusedIds.pop();
            data.squads[newId] = _squad;
        }else{
            data.squads.push(_squad);
    		newId = data.squads.length  - 1;
        }
    }
    
    function remove(SquadSet storage data, uint256 id) internal{
        data.unusedIds.push(id);
        delete data.toState[id];
        delete data.toOwner[id]; //Not necessary but this way it doesn't show up erroneously 
        data.toCount[data.toOwner[id]]-=1;
    }
    
    function get(SquadSet storage data, uint256 id) internal view returns(Squad storage){
        return data.squads[id];
    }
    
    function getUnit(SquadSet storage data, uint256 id, uint256 uid) internal view returns (uint256){
        return get(data,id).unitIds[uid];
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
        require(auction.endTime >= block.timestamp, "It is too late to bid!");
        //preapprove the transaction to the Auction
        currency.spend(msg.sender, _value);
        //remove hold on previous highest bidders currency
        currency.deposit(auction.highestBidder, auction.highestBid);
        auction.highestBid = _value;
        auction.highestBidder = msg.sender;
    }
    
    function bid(AuctionSet storage auctionData, uint256 id, uint256 _value, StoreToken currency) internal{
        return bid(auctionData.auctions[id],_value,currency);
    }
    
    
    function settle(Auction storage auction, UnitSet storage unitData, StoreToken currency) public{
        //if nobody bid just close the auction
        if(auction.host == auction.highestBidder){
            for (uint i=0; i < auction.assetIds.length; i++){
                unitData.toState[auction.assetIds[i]] = UnitState.Default;
            }
        
        }else{
            for (uint i=0; i < auction.assetIds.length; i++){
                UnitHelpers.transfer(unitData,auction.highestBidder,auction.host,auction.assetIds[i]);
                currency.deposit(auction.host, auction.highestBid);
            }
        }
    }
    
    
    
    function createAuction(AuctionSet storage auctionData, uint256[] calldata _assets, uint256 _asking, string calldata title) public returns(uint256 auctionId){
        auctionId = add(auctionData,Auction({
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
            auctionData.auctions[auctionId].assetIds.push(_assets[i]);
        }
    }
    
    function add(AuctionSet storage data, Auction memory _auction) internal returns (uint256 newId){
        if(data.unusedIds.length > 0){
            newId = data.unusedIds[data.unusedIds.length -1];
            data.unusedIds.pop();
            data.auctions[newId] = _auction;
        }else{
            data.auctions.push(_auction);
    		newId = data.auctions.length  - 1;
        }
    }
    
    function remove(AuctionSet storage data, uint256 id) internal{
        data.unusedIds.push(id);
        delete data.auctions[id];
    }
    
    function get(AuctionSet storage data, uint256 id) internal view returns(Auction storage){
        return data.auctions[id];
    }
}

// has all the basic data etc
contract AutoChessBase{
    UnitSet unitData;
    SquadSet squadData;
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
    //TODO fill in this bit
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract UnitToken is AutoChessBase, ERC721{

    //TODO remove hard coded value
    uint256 private totalUnits = 1000000000;
    using UnitHelpers for UnitSet;
    
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
    


    function transfer(address _to, uint256 _tokenId) public _validTx(msg.sender,_to, _tokenId) override {
        unitData.transfer(msg.sender,_to,_tokenId);
        emit Transfer(msg.sender,_to,_tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public _validTx(_from,_to,_tokenId) override {
        require(unitData.toApproved[_tokenId] == _to, "Unit is not promised to that user");
        //Require that it is not in a squad (this could be changed to something smarter)
        //Example uses double map
        unitData.transfer(_from,_to,_tokenId);
        emit Transfer(_from,_to,_tokenId);
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
        tokenIds = new uint256[](unitData.toCount[_owner]);
        for(uint i=0; i < unitData.units.length;i++){
           if(unitData.toOwner[i] == _owner){
            tokenIds[count++] = i;
           }
        }
    }

    function getToken(uint256 tokenId) public view returns(Unit memory){
        return unitData.units[tokenId];
    }
    
    function getUnitState(uint256 unitId) public view returns(UnitState state){
        return unitData.toState[unitId];
    }
    //function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) public view override returns (string memory infoUrl){}

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    //function supportsInterface(bytes4 _interfaceID) public view override returns (bool) {}
}	

// File: UnitMarketplace.sol


interface IUnitMarketplace{
    
    function bid(uint256 _auctionId, uint256 _value) external;
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) external;
    function startAuction(uint256[] calldata _assets, uint256 _asking,string calldata title) external returns(uint256 auctionId);
    function withdrawAuction(uint256 _auctionId) external;
}


contract UnitMarketplace is UnitToken,IUnitMarketplace {
    //objects:
    using AuctionFunctions for AuctionSet;
    using AuctionFunctions for Auction;
    StoreToken public CurrencyProvider = new StoreToken(address(this));
    
    //A list of all ongoing auctions
    AuctionSet auctionData;
    
    function bid(uint256 _auctionId, uint256 _value) public override {
       auctionData.bid(_auctionId,_value, CurrencyProvider);
    }

    /// So people can bid with a message etc
    /// just for funzies
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) public override {
        auctionData.bid(_auctionId,_value, CurrencyProvider);
        auctionData.auctions[_auctionId].highestBidText = _msg;
    }

    function auctionApprove(address _from, uint256 _tokenId) internal {
        require(_from == ownerOf(_tokenId),"You don't own this unit");
        require(unitData.toState[_tokenId] == UnitState.Default, "Unit is unavailable");
        require(_from != address(0));
        unitData.toState[_tokenId] = UnitState.Auctioning;
    }
    
    function auctionTransfer(address _to, uint256 _tokenId) internal {
        require(unitData.toState[_tokenId] == UnitState.Auctioning, "Unit is not in auction");
        unitData.toState[_tokenId] = UnitState.Default;
        delete unitData.toApproved[_tokenId];
        unitData.toOwner[_tokenId] = _to;
        unitData.toCount[_to]+=1;
    }

    function startAuction(uint256[] calldata _assets, uint256 _asking, string calldata title) external override returns(uint256 auctionId) {
        //transfer all the assets to the auctionhouse
        for(uint i =0; i < _assets.length; i++){
            auctionApprove(msg.sender,_assets[i]);
        }
        auctionId = AuctionFunctions.createAuction(auctionData, _assets, _asking, title);
    }
    
    function claimAuction(uint256 _auctionId) public {
        auctionData.get(_auctionId).settle(unitData, CurrencyProvider);
        auctionData.remove(_auctionId);
    }
    
    function withdrawAuction(uint256 _auctionId) public override{
        require(auctionData.get(_auctionId).host == msg.sender, "You are not the host of this auction!");
        require(auctionData.get(_auctionId).highestBidder == msg.sender);
        
        //withdraw the highestbidders bid
        for (uint i=0; i < auctionData.get(_auctionId).assetIds.length; i++){
                unitData.toState[auctionData.get(_auctionId).assetIds[i]] = UnitState.Default;
        }
    }

    function getAssetIds(uint256 _auctionId) public view returns(uint256[] memory){
        return auctionData.get(_auctionId).assetIds;
    }

    function getAuctionCount() public view returns(uint256 count){
        return auctionData.auctions.length;
    }
    
    function getAuctions() public view returns(Auction[] memory){
        return auctionData.auctions;
    }
    //TODO add reverse auctions where someone offers tokens. Maybe?
}

// File: SquadBuilder.sol



interface ISquadBuilder{
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
    
    
    function _buyUnit(address _owner, UnitType _type, string memory _name) internal returns (uint256 _unitId){
        uint256 _cost = _type.getCost();
        CurrencyProvider.spend(_owner,_cost);
        _unitId = UnitHelpers.createUnit(unitData, _type, _name);
        emit UnitCreated(_owner,_unitId);
        unitData.toOwner[_unitId] = _owner;
        unitData.toCount[_owner]+=1;
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
        emit SquadCreated(_owner,squadId);
    }
    
   
    
}

// File: GameEngine.sol

/// handles the game calculations and logic etc


/// Handles the actual playing of the game
contract GameEngine is SquadBuilder{

    using UnitHelpers for Unit;
    using SquadHelpers for Squad;
    using SquadHelpers for SquadSet;
    uint8 constant ROUNDLIMIT = 2;
    
    function _squadBattle(uint attackerSquadId, uint defenderSquadId) internal returns(uint16 winnings) {
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
        for(uint8 i=0; i < ROUNDLIMIT && atkNum > 0 && dfdNum > 0;i++) {
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
        
        //update defender squad
        winnings = squadData.afterBattle(unitData, defenderSquadId, dfdNum);
        //stash the attackers winnings
        squadData.get(attackerSquadId).stashedTokens += winnings;
        CurrencyProvider.deposit(squadData.toOwner[defenderSquadId],squadData.get(defenderSquadId).stashedTokens);
    }
    
    
}

// File: MatchMaker.sol

/// connects players and arranges for who plays what games

///handles all the adding of units and whatnot

interface IMatchMaker{
    
    function targetedChallenge(uint256[] calldata unitIds, uint256 _targetId) external returns (uint256 squadId);
    function getSquadIdsInTier(DeploymentState _tier) external view returns (uint256[] memory deployed); //This is subject to change
}


contract MatchMaker is GameEngine, IMatchMaker{
    using SquadHelpers for SquadSet;
    /// Calls the parent constructor
    constructor(){
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
        require(unitData.toCount[address(this)] <= 16, "hmmm");
        //make all the units into a squad
        _createSquad(address(this), _ids7);
        _createSquad(address(this), _ids5);
        _createSquad(address(this), _ids3);
        _createSquad(address(this), _ids1);
   }
   

    function targetedChallenge(uint256[] calldata _unitIds, uint256 targetId) public override returns (uint256 squadId){
        DeploymentState tier;
        (squadId, tier) = _createSquad(msg.sender,_unitIds);
        
        //make sure it's a valid target
        require(squadId != targetId, "unit can't fight itself");
        _squadBattle(squadId,targetId);
    }


    function getSquadIdsInTier(DeploymentState _tier) public override view returns (uint256[] memory squadIds){
        require(_tier != DeploymentState.Unused, "Invalid choice");
        uint256 count;
        squadIds = new uint256[](squadData.toTierSize[_tier]);
        for(uint i=0; i < squadData.squads.length;i++){
           if(squadData.toState[i] == _tier){
            squadIds[count++] = i;
           }
        }
    }
    
    function squadsOf(address _owner) public view returns (uint256[] memory squadIds){
        uint256 count;
        squadIds = new uint256[](squadData.toCount[_owner]);
        for(uint i=0; i < squadData.squads.length;i++){
           if(squadData.toOwner[i] == _owner){
            squadIds[count++] = i;
           }
        }
    }
    
    function squadCount(address _owner) public view returns(uint256){
        return squadData.toCount[_owner];
    }
    
    function getSquadState(uint256 squadId) public view returns(DeploymentState){
        return squadData.toState[squadId];
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
    
    
}
