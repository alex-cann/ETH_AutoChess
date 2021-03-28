/// handles the auctioning of units etc

pragma solidity ^0.8.1;

import "./UnitToken.sol";
import "./StoreToken.sol";
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

//TODO add autobidding ()
contract UnitMarketplace is UnitToken,IUnitMarketplace {
    //objects:

    address ProviderAddress;
    StoreToken CurrencyProvider;

    //A list of all ongoing auctions
    Auction[] _auctions;

    constructor() {
        CurrencyProvider = new StoreToken();
        ProviderAddress = address(CurrencyProvider);
    }

    function bid(uint256 _auctionId, uint256 _value) public override returns(bool success) {
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
                        assetIds: _assets,
                        highestBidText: "Default Bid",
                        endTime: block.timestamp + 1 hours
                        }));
        //transfer all the assets to the auctionhouse
        for(uint i =0; i < _assets.length; i++){
            _transfer(msg.sender,address(this),_assets[i]);
        }
        //TODO add an auction event
        return true;
    }

    function withdrawAuction(uint256 _auctionId) public override returns(bool success){
        assert(_auctions[_auctionId].host == msg.sender);
        assert(_auctions[_auctionId].endTime < block.timestamp);
        //TODO call withdraw bid function

        //TODO reset ownership of units back to the host or use approval system instead
        return true;
    }


    //TODO add withdraw bid function

    //TODO add reverse auctions where someone offers tokens    
}
