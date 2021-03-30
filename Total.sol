/// handles the auctioning of units etc
pragma solidity ^0.8.1;


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

interface IUnitToken is IAutoChessBase, ERC721{

}


interface IUnitMarketplace {
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

interface ISquadBuilder is IUnitMarketplace{

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

contract UnitToken is AutoChessBase, IUnitToken {
    //TODO fill these in
    // Required methods

    //TODO remove hard coded value
    uint256 private totalUnits = 1000000000;


    function totalSupply() public view override returns (uint256 total) {
        return totalUnits;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return ownerToUnitCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        //TODO set this check up later
        require(unitIndexExists[_tokenId]);
        return unitIndexToOwner[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public override {
        require (msg.sender == ownerOf(_tokenId),"You don't own this token");
        require(msg.sender != _to, "No self approved transactions!");
        require(unitIndexToState[_tokenId] == UnitState.Default, "Unit is Occupied!");
        allowed[msg.sender][_to] = _tokenId;
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



    function transfer(address _to, uint256 _tokenId) override public {
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
        require(unitIndexToAllowed[_tokenId] == _to); //this can only be set if the unit is in Promised
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
    //function tokensOfOwner(address _owner) public view override returns (uint256[] memory tokenIds){}

    //function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) public view override returns (string memory infoUrl){}

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public view override returns (bool) {

    }
}	
contract StoreToken is ERC20 {
    //TODO support fancy bidding where you can approve more than you actually have

    uint256 private totalTokens = 1000000000;
    mapping (address => uint256) ownerToBalance;
    mapping (address => mapping(address => uint256)) ownerToApprovedWithdrawals;
    mapping (address => uint256) ownerToTotalApproved;
    address StoreAddress;

    constructor() {
        //this contract is aware that the store owns it but not of the stores ABI
        StoreAddress = msg.sender;
    }

    ///@dev functions only accessible from the marketplace (so coins can be autoApproved for auctions)
    modifier _storeOnly() {
        require(msg.sender == StoreAddress);
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
        require(ownerToApprovedWithdrawals[_from][_to] > _value);
        
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
        require(unApprovedBalanceOf(_from) > _value);
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

//TODO add autobidding ()
contract UnitMarketplace is UnitToken,IUnitMarketplace {
    //objects:

    address public ProviderAddress;
    StoreToken public CurrencyProvider;

    //A list of all ongoing auctions
    Auction[] public _auctions;

    constructor() {
        CurrencyProvider = new StoreToken();
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


contract SquadBuilder is UnitMarketplace, ISquadBuilder {

    //TODO implement this so that units can be efficiently deleted etc
    //other approach is to update id of last unit(probably a bad idea)
    uint256[] unusedIndices;
    string constant DEFAULT_NAME = "Maurice, the Mediocre";
    /// @dev creates and stores a new unit
    function _generateUnit(UnitType _type,string memory _name) internal returns (uint)
    {
        Unit memory _unit = Unit({
                            attack: randomNumber(3),
                            defence: randomNumber(2),
                            //functions as a multiplier on the other attributes
                            level: 1,
                            //starting health of unit
                            maxHealth: randomNumber(20),
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
        if(unusedIndices.length == 0){
            units.push(_unit);
            newUnitId = units.length  - 1;
        }else{
            //get the latest unused Index
            newUnitId = unusedIndices[unusedIndices.length - 1];
            //delete from the list of unused Indices since it is now used
            unusedIndices.pop();
        }
        return newUnitId;
    }
    
    function _buyUnit(UnitType _type, string memory _name) public returns (uint256 _unitId){
        uint256 _cost = 0;
        uint256 _id;
        if(_type == UnitType.Warrior){
            _cost+=10;
        }else if(_type == UnitType.Archer){
            _cost+=15;
        }else if(_type == UnitType.Cavalry){
            _cost+=20;
        }
        CurrencyProvider.spend(msg.sender,_cost);
        _id = _generateUnit(_type, _name);
        unitIndexToOwner[_id] = msg.sender;
        ownerToUnitCount[msg.sender]+=1;
        ownerToUnitIndices[msg.sender].push(_id);
        return _id;
    }
    
    function buyUnit(UnitType _type) public returns (uint256 _unitId){
        return _buyUnit(_type, DEFAULT_NAME);
    }
    
    function buyUnit(UnitType _type, string calldata _name) public returns (uint256 _unitId){
        return _buyUnit(_type,_name);
    }
    
    
    // create squad
    function _createSquad(uint256[] calldata _unitIds) internal returns(uint256 squadId, DeploymentState tier){
        uint16 atkSum=0;
        //TODO make sure that _unitIds is one of the correct lengths
        for(uint8 i=0; i < _unitIds.length; i++){
            require(unitIndexToOwner[_unitIds[i]] == msg.sender);
            require(unitIndexToState[_unitIds[i]] == UnitState.Default);//check that this unit isn't doing something else
            unitIndexToState[_unitIds[i]] = UnitState.Deployed;
            atkSum+=units[_unitIds[i]].attack;
        }

        DeploymentState _tier = _getTier(_unitIds.length);
        squads.push(Squad({
                    unitIds: new uint256[](0),
                    unitCount:uint8(_unitIds.length),
                    state:_tier,
                    deployTime:uint16(block.timestamp), //TODO this seems sketch
                    totalAttack:atkSum,
                    stashedTokens:0
                    }));
        //TODO figure out a better way of making this work
        //https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb
         for(uint8 i=0; i < _unitIds.length; i++){
            squads[squads.length - 1].unitIds.push(_unitIds[i]);
        }            
        return (squads.length ,_tier);
    }
}

