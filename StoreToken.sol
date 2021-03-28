///ERC20 token used to buy units from the store etc

pragma solidity ^0.8.1;

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

    constructor() {
        //this contract is aware that the store owns it but not of the stores ABI
        StoreAddress = msg.sender;
    }

    ///@dev functions only accessible from the marketplace (so coins can be autoApproved for auctions)
    modifier _storeOnly() {
        assert(msg.sender == StoreAddress);
        _;
    }

    function totalSupply()  public view override returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return ownerToBalance[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balanceOf(msg.sender) > _value);
        ownerToBalance[msg.sender] -= _value;
        //TODO check for edge cases
        ownerToBalance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        //is this person authorized to withdraw this money
        require(ownerToApprovedWithdrawals[_from][_to] > _value);
        require(ownerToBalance[_from] > _value);

        ownerToApprovedWithdrawals[_from][_to] -= _value;
        ownerToTotalApproved[_from] -= _value;
        ownerToBalance[_from] -= _value;
        ownerToBalance[_to] += _value;
        return true;
    }

    function autoApprove(address _from, uint256 _value) public _storeOnly returns (bool success) {
        return _approve(_from, StoreAddress, _value);
    }

    function autoUnApprove(address _from, uint256 _value) public _storeOnly returns (bool success) {
        ownerToApprovedWithdrawals[_from][msg.sender] -= _value;
        ownerToTotalApproved[_from] -= _value;
        return true;
    }

    function _approve(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(ownerToBalance[_from] > (_value + ownerToTotalApproved[msg.sender]));
        ownerToApprovedWithdrawals[_from][_to] += _value;
        ownerToTotalApproved[_from] += _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return _approve(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return ownerToApprovedWithdrawals[_owner][_spender];
    }
    //TODO add buy with ethereum functionality

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
