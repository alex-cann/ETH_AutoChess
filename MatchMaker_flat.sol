
// File: StoreToken.sol

///ERC20 token used to buy units from the store etc

pragma solidity ^0.8.1;
//SPDX-License-Identifier: UNLICENSED
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

// File: AutoChess.sol


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
    //To check if a unit exists check if it's sate is dead
    enum UnitState {
        Dead,Deployed,Auctioning,Default,Promised
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
    Unit[] public units;

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
        if(_unitCount == 1){
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


interface IUnitToken is IAutoChessBase, ERC721{

}

contract UnitToken is AutoChessBase, IUnitToken {
    //TODO fill these in
    // Required methods

    //TODO remove hard coded value
    uint256 private totalUnits = 1000000000;

    modifier _validTx(address _from, address _to, uint256 _tokenId){
        require(_from == ownerOf(_tokenId),"You don't own this unit");
        require(_from != _to, "You already own this unit");
        require(unitIndexToState[_tokenId] == UnitState.Default, "Unit is unavailable");
        require(_to != address(0), "Not a valid address. Sorry!");
        _;
    }
    
    function totalSupply() public view override returns (uint256 total) {
        return totalUnits;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return ownerToUnitCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        return unitIndexToOwner[_tokenId];
    }
    
    function approve(address _to, uint256 _tokenId) public _validTx(msg.sender,_to, _tokenId) override {
        unitIndexToAllowed[_tokenId] = _to;
        unitIndexToState[_tokenId] = UnitState.Promised;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerToUnitCount[_from]-=1;
        unitIndexToOwner[_tokenId] = _to;
        //remove any allowances on transfering this unit
        delete unitIndexToAllowed[_tokenId];
        //set it to default
        unitIndexToState[_tokenId] = UnitState.Default;
        ownerToUnitCount[_to]+=1;
        //the contract calling this is the unit generator
        //Trigger the transfer Event
        emit Transfer(_from,_to,_tokenId);
    }


    function transfer(address _to, uint256 _tokenId) public _validTx(msg.sender,_to, _tokenId) override {
        _transfer(msg.sender,_to,_tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public _validTx(_from,_to,_tokenId) override {
        require(unitIndexToAllowed[_tokenId] == _to, "Unit is not promised to that user");
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

    //TODO fill these in
    function tokensOfOwner(address _owner) public view override returns (uint256[] memory tokenIds){
        return ownerToUnitIndices[_owner];
    }

    //function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) public view override returns (string memory infoUrl){}

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public view override returns (bool) {

    }
}	

// File: UnitMarketplace.sol




interface IUnitMarketplace is IUnitToken{
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

    function bid(uint256 _auctionId, uint256 _value) external returns(bool success);
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) external returns(bool success);
    function startAuction(uint256[] calldata _assets, uint256 _asking) external returns(bool success);
    function withdrawAuction(uint256 _auctionId) external returns(bool success);
}


contract UnitMarketplace is UnitToken,IUnitMarketplace {
    //objects:

    address public ProviderAddress;
    StoreToken public CurrencyProvider;

    //A list of all ongoing auctions
    Auction[] public _auctions;

    constructor() {
        CurrencyProvider = new StoreToken(address(this));
        ProviderAddress = address(CurrencyProvider);
    }

    function bid(uint256 _auctionId, uint256 _value) public override returns(bool success) {
        Auction memory auction = _auctions[_auctionId];
        //check if this bid is big enough
        require(_value > auction.highestBid, "This is not a new highest bid!");
        //preapprove the transaction to the Auction
        CurrencyProvider.autoApprove(msg.sender, _value);
        //remove hold on previous highest bidders currency
        CurrencyProvider.autoUnApprove(auction.highestBidder,auction.highestBid);
        auction.highestBid = _value;
        auction.highestBidder = msg.sender;
        return true;
    }

    /// So people can bid with a message etc
    /// just for funzies
    function bid(uint256 _auctionId, uint256 _value,string calldata _msg) public override returns(bool success) {
        assert(bid(_auctionId,_value));
        _auctions[_auctionId].highestBidText = _msg;
        return true;
    }

    function startAuction(uint256[] calldata _assets, uint256 _asking) public override returns(bool success) {
        //TODO verify that all the units up for auction aren't in a squad etc
        _auctions.push(Auction({
                        highestBid:_asking,
                        highestBidder: msg.sender,
                        host: msg.sender,
                        name: "PLACEHOLDER",
                        assetIds: new uint256[](0),
                        highestBidText: "Default Bid",
                        endTime: block.timestamp + 1 hours
                        }));
        //transfer all the assets to the auctionhouse
        for(uint i =0; i < _assets.length; i++){
            _transfer(msg.sender,address(this),_assets[i]);
            _auctions[_auctions.length - 1].assetIds.push(_assets[i]);
        }
        //TODO add an auction event
        return true;
    }

    function withdrawAuction(uint256 _auctionId) public override returns(bool success){
        //TODO make sure this auction actually exists
        Auction memory auction = _auctions[_auctionId];
        require(auction.host == msg.sender, "You are not the host of this auction!");
        require(auction.endTime > block.timestamp, "It is too late to withdraw this auction!");
        //withdraw the highestbidders bid
        CurrencyProvider.autoUnApprove(auction.highestBidder,auction.highestBid);
        //TODO reset ownership of units back to the host or use approval system instead
        return true;
    }

    //TODO add reverse auctions where someone offers tokens. Maybe?
}

// File: SquadBuilder.sol



interface ISquadBuilder is IUnitMarketplace{
    function buyUnit(UnitType _type) external returns (uint256 _unitId);
    function buyUnit(UnitType _type, string memory _name) external returns (uint256 _unitId);
    event UnitCreated(address owner, uint256 indexed  id);
    event SquadCreated(address owner, uint256 _id);
}

contract SquadBuilder is UnitMarketplace, ISquadBuilder {

    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    uint256[] unusedIndices;
    string constant DEFAULT_NAME = "Maurice, the Mediocre";
    /// @dev creates and stores a new unit
    
    constructor() UnitMarketplace(){}
    
    function _generateUnit(UnitType _type,string memory _name) internal returns (uint)
    {
        Unit memory _unit = Unit({
                            attack: 0,
                            defence: 0,
                            //functions as a multiplier on the other attributes
                            level: 1,
                            //starting health of unit
                            maxHealth: 0,
                            // health remaining on this unit
                            curHealth: 0,
                            //what type of unit this is
                            utype: _type,
                            //A name associated with this unit
                            name: _name
                            });

        if (_type == UnitType.Archer) {
            // archer, high attack
            _unit.attack += 15;
            _unit.defence += 1;
            _unit.maxHealth += 50;
        } else if (_type == UnitType.Warrior) {
            // warrior, high defence
            _unit.attack += 10;
            _unit.defence += 5;
            _unit.maxHealth += 50;
        } else if (_type == UnitType.Cavalry){
            // cavalry, high health
            _unit.attack += 10;
            _unit.defence += 1;
            _unit.maxHealth += 75;
        }

        // create units with max health
        _unit.curHealth = _unit.maxHealth;

        //TODO modify this now that unitIDS are permanent
        uint256 newUnitId;
		units.push(_unit);
		require(units.length > 0, "units should not be empty");
		newUnitId = units.length  - 1;
        unitIndexToState[newUnitId] = UnitState.Default;
        return newUnitId;
    }
    
    function _buyUnit(address _owner, UnitType _type, string memory _name) internal returns (uint256 _unitId){
        uint256 _cost = 0;
        uint256 _id;
        if(_type == UnitType.Warrior){
            _cost+=10;
        }else if(_type == UnitType.Archer){
            _cost+=15;
        }else if(_type == UnitType.Cavalry){
            _cost+=20;
        }else{
            require(false, "Not a valid unit type");
        }
        
        CurrencyProvider.spend(_owner,_cost);
        _id = _generateUnit(_type, _name);
        emit UnitCreated(_owner,_id);
        unitIndexToOwner[_id] = _owner;
        ownerToUnitCount[_owner]+=1;
        ownerToUnitIndices[_owner].push(_id);
        return _id;
    }
    
    function buyUnit(UnitType _type) public override returns (uint256 _unitId){
        return _buyUnit(msg.sender, _type, DEFAULT_NAME);
    }
    
    function buyUnit(UnitType _type, string calldata _name) public override returns (uint256 _unitId){
        return _buyUnit(msg.sender,_type,_name);
    }
    
    
    // create squad
    //TODO remove the workaround where you have to send 7 unitIds
    function _createSquad(address _owner, uint256[] memory _unitIds) internal returns(uint256 squadId, DeploymentState tier){
        uint16 atkSum=0;
        //TODO make sure that _unitIds is one of the correct lengths
        require(_unitIds.length <= 7, "Invalid number of units");
        for(uint8 i=0; i < _unitIds.length; i+=1){
            require(unitIndexToOwner[_unitIds[i]] == _owner, "You don't own this unit!");
            require(unitIndexToState[_unitIds[i]] == UnitState.Default, "Unit is busy");//check that this unit isn't doing something else
            unitIndexToState[_unitIds[i]] = UnitState.Deployed;
            atkSum+=units[_unitIds[i]].attack;
        }
        DeploymentState _tier = _getTier(_unitIds.length);
        Squad memory _squad = Squad({
                    unitIds: new uint256[](0),
                    unitCount:uint8(_unitIds.length),
                    state:_tier,
                    deployTime:uint16(block.timestamp), //TODO this seems sketch
                    totalAttack:atkSum,
                    stashedTokens:0
                    });
                    
        squads.push(_squad);
        //TODO figure out a better way of making this work
        //https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb
         for(uint8 i=0; i < _unitIds.length; i+=1){
            squads[squads.length - 1].unitIds.push(_unitIds[i]);
        }
        
        ownerToSquadIndex[_owner].push(squads.length -1);
        squadIndexToOwner[squads.length - 1] = _owner;
        emit SquadCreated(_owner,squads.length-1);
        return (squads.length-1,_tier);
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
    
    function unitDeath(uint256 _unitId) internal returns (bool success){
        return true;
    }

    //TODO This doesn't match what was discussed on Friday
    function _squadBattle(uint attackerSquadId, uint defenderSquadId) internal returns(uint winnings) {
        Squad memory attacker = squads[attackerSquadId];
        Squad memory  defender = squads[defenderSquadId];

        require(attacker.state == defender.state);
        require(attacker.state != DeploymentState.Retired);
        
        //Making these storage variables is very dubious
       
        uint8 atkNum = attacker.unitCount;
        uint8 dfdNum = defender.unitCount;
        Unit[] memory atkUnits = new Unit[](atkNum);
        Unit[] memory dfdUnits = new Unit[](dfdNum);
        
        for (uint8 i=0; i<atkNum; i++) {
            atkUnits[i] = units[attacker.unitIds[i]];
            dfdUnits[i] = units[defender.unitIds[i]];
        }

        //TODO include more details wrt squad formation
        //     also include formation in the Squad structure
        uint atkIdxAP;
        uint atkIdxDP;
        uint dfdIdxAP;
        uint dfdIdxDP;

        while (atkNum > 0 && dfdNum > 0) {
            //TODO why is this random ordering it allows for users to structure squads better
            //otherwise why does it matter that you have warriors etc if enemies will randomly hit your archers
            
            // attacker attacks phase
            // choose attacker unit
            atkIdxAP = randomNumber(attacker.unitIds.length);
            while(atkUnits[atkIdxAP].curHealth <= 0) {
                atkIdxAP = (atkIdxAP + 1) % attacker.unitIds.length;
            }

            // choose defending unit
            dfdIdxAP = randomNumber(defender.unitIds.length);
            while(dfdUnits[dfdIdxAP].curHealth <= 0) {
                dfdIdxAP = (dfdIdxAP + 1) % defender.unitIds.length;
            }

            // attack happens
            // TODO maybe add fancy stuff here
            //      like counter attack or something similar
            dfdUnits[dfdIdxAP].curHealth -= (atkUnits[atkIdxAP].attack - dfdUnits[dfdIdxAP].defence);

            if (dfdUnits[dfdIdxAP].curHealth <= 0) {
                //TODO handle unit death
                dfdNum--;
            }

            // defender attacks phase
            // choose attacker unit
            atkIdxDP = randomNumber(defender.unitIds.length);
            while(dfdUnits[atkIdxDP].curHealth <= 0) {
                atkIdxDP = (atkIdxDP + 1) % defender.unitIds.length;
            }

            // choose defender unit
            dfdIdxDP = randomNumber(attacker.unitIds.length);
            while(atkUnits[dfdIdxDP].curHealth <= 0) {
                dfdIdxDP = (dfdIdxDP + 1) % attacker.unitIds.length;
            }

            // attack happens
            atkUnits[dfdIdxDP].curHealth -= (dfdUnits[atkIdxDP].attack - atkUnits[dfdIdxDP].defence);

            if (atkUnits[dfdIdxDP].curHealth <= 0) {
                //TODO handle unit death
                atkNum--;
            }
        }

        // copy defender squad units state back to chain
        for (uint8 i=0; i<dfdUnits.length; i++) {
            units[defender.unitIds[i]] = dfdUnits[i];
        }
        defender.unitCount = dfdNum;
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

    function randomChallenge(uint256[] calldata unitIds) external returns (uint256 winnings);
    function targetedChallenge(uint256[] calldata unitIds, uint256 _targetId) external returns (uint256 winnings);
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
        
        require(units.length<=16,"too many units created");
        //TODO figure out why this fixes things
        require(ownerToUnitIndices[address(this)].length <= 16, "hmmm");
        //make all the units into a squad
        _createSquad(address(this), _ids7);
        _createSquad(address(this), _ids5);
        _createSquad(address(this), _ids3);
        _createSquad(address(this), _ids1);
   }

    //TODO make this create a squad
    function randomChallenge(uint256[] calldata _unitIds) public override returns (uint256 winnings){
        uint256 squadId;
        DeploymentState tier;
        (squadId, tier) = _createSquad(msg.sender, _unitIds);
        uint256 targetId = randomNumber(tierToSquadIndex[tier].length);
        return _squadBattle(squadId,targetId);//TODO update this so that wining sgo on the squad and the id is returned instead
    }


    function targetedChallenge(uint256[] calldata _unitIds, uint256 _targetId) public override returns (uint256 winnings){
        uint256 squadId;
        DeploymentState tier;
        (squadId, tier) = _createSquad(msg.sender,_unitIds);
        //make sure it's a valid target
        assert(tierToSquadIndex[tier].length > _targetId);
        return _squadBattle(squadId,_targetId);
    }


    function getSquadIdsInTier(DeploymentState _tier) public override view returns (uint256[] memory deployed){
        return tierToSquadIndex[_tier];
    }



    function withdrawSquad(uint256 _squadId) public override returns (bool success){

    }
}
