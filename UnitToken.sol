pragma solidity ^0.8.1;
//SPDX-License-Identifier: UNLICENSED


///implementation based on https://medium.com/crypto-currently/the-anatomy-of-erc721-e9db77abfc24
/// Handles ERC771 implementation of units

import "./AutoChess.sol";

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
    //function tokensOfOwner(address _owner) public view override returns (uint256[] memory tokenIds){}

    //function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) public view override returns (string memory infoUrl){}

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public view override returns (bool) {

    }
}	
