///implementation based on https://medium.com/crypto-currently/the-anatomy-of-erc721-e9db77abfc24
/// Handles ERC771 implementation of units

pragma solidity ^0.8.1;

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

contract UnitToken is AutoChessBase, IUnitToken{ 
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
        require(unitIndexToState[_tokenId] == UnitState.Default);
        //TODO set this check up later
        //allowed[msg.sender][_to] = _tokenId;
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal{
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
    function supportsInterface(bytes4 _interfaceID) public view override returns (bool){
        
    }
}	
