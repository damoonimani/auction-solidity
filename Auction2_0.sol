// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Aution2 {

// address for owner (auctioneer) and contract  and  deployment time
    address public auctioneer;
    address public contractAddress;

 // details of auction wrapped in struct
    struct AuctionDetails {
     string productName;
     string productDesc;
     uint256 collateral;
     uint256 enrollmentFee;
     uint256 presetBidding;
     uint256 timeWindow;
     uint256 startTime;
     bool started;
     bool finished;
    }

    AuctionDetails public auction;

// saving transaction reciept in struct
    struct Reciept {
        string txidCOLL;
        string txidEFEE;
    }

    mapping(address => Reciept) public participants;

    event PaidCollateral(address participant, uint256 amount, bool status );
    event PaidEnrollmentFee(address participant, uint256 amount, bool status );
    event Participated(address participant, string txidCOLL, string txidEFEE );

    constructor() {
       auctioneer =  msg.sender;
       contractAddress = address(this);
    }

    // Phase III needs access code genrated
    mapping(address => uint256) public bidders;

    // Phase IV needs state variables to track current highest bidder and highest amount
    uint256 public currentBid;
    address public currentBidder;
    uint256 public currentBidTime;

    // state variable to track winner
    address public winner;

    // modifiers

    // only auctioneer can use the function
    modifier onlyAuctioneer {
        require(msg.sender == auctioneer);
        _;
    }

    modifier onlyWinner {
        require(msg.sender == winner);
        _;
    }

    modifier afterEnrollmentWindow {
        require(block.timestamp >= auction.startTime + auction.timeWindow);
        _;
    }


    modifier afterFinished {
        require(auction.finished == true);
        _;
    }

    modifier beforeFinished {
        require(auction.finished != true);
        _;
    }

    modifier beforeEnrollmentWindow {
        require(block.timestamp < auction.startTime + auction.timeWindow);
        _;
    }

    // Phase I - The auctioneer can launch an auction.
    // At the first phase, the auction is initiated as a smart contract
    // for a particular digital asset with these items:

    // Full specification of the digital asset
    // Declaration of Collateral ( in Ethereum (ETH))
    // Declaration of Enrolment fee ( in Ethereum (ETH))
    // Introducing an Ethereum (ETH) wallet address for both Collateral and Enrolment fee
    // Announcement of Enrolment Time Window
    // Announcement of Preset Bidding
    // Announcement of the contract ID

    function launchAuction(
    string memory _productName,
    string memory _productDescription,
    uint256 _collateral,
    uint256 _enrollmentFee,
    uint256 _timeWindow,
    uint256 _presetBidding
    ) public onlyAuctioneer {
       auction = AuctionDetails(_productName, _productDescription,
       _collateral, _enrollmentFee, _timeWindow, block.timestamp,
       _presetBidding, false, false);
    }


    // Phase II
    // participants send Txid-COLL and Txid-EFEE and their wallet address to participate
    // participants can use payEnrollmentFee and payCollateral to recieve Txid-COLL and Txid-EFEE

    function participate(string memory _txidCOLL, string memory _txidEFEE) public beforeEnrollmentWindow {
        participants[msg.sender] = Reciept(_txidCOLL, _txidEFEE);
        emit Participated(msg.sender, _txidCOLL, _txidEFEE);
    }

    function payEnrollmentFee() public payable beforeEnrollmentWindow {
        require(msg.value >= (auction.enrollmentFee) * 1000000000000000000, " fee was not correct");
        (bool sent,  ) =  auctioneer.call{value: (auction.enrollmentFee * 1000000000000000000)}("");
        require(sent, "Failed to send Ether");
        emit PaidEnrollmentFee(msg.sender, msg.value, sent);
    }

    function payCollateral() public payable beforeEnrollmentWindow {
        require(msg.value >= (auction.collateral) * 1000000000000000000, "collateral  was not correct");
        (bool sent,  ) =  auctioneer.call{value: (auction.collateral * 1000000000000000000)}("");
        require(sent, "Failed to send Ether");
        emit PaidCollateral(msg.sender, msg.value, sent);

    }

    // Phase III
    // auctioneer can access Reciept for any participants
    // in other function auctioneer can add participant to list of bidders

    function getParticipant(address _participant) public view returns(string memory _txidCOLL, string memory _txidEFEE) {
        return (participants[_participant].txidCOLL, participants[_participant].txidEFEE);
    }

    function addBidders(address _participant, uint256 _privilegeCode) public onlyAuctioneer beforeEnrollmentWindow{
        bidders[_participant] = _privilegeCode;
    }


    // Phase IV
    // auction starts using startAuction
    // in another function people can place bids
    // state variable of current bid and current bidder mutates every time a bid is placed
    // bidding happens if auction has not ended [modifier]
    // bidding happens if auction has already started [modifier]

    function startAuction() public onlyAuctioneer afterEnrollmentWindow beforeFinished{
        auction.started = true;
        currentBid = auction.presetBidding;
    }

    function bid(uint256 _value) public afterEnrollmentWindow beforeFinished{
        if(block.timestamp < currentBidTime + 1 minutes) {
        currentBid = _value;
        currentBidder = msg.sender;
        currentBidTime = block.timestamp;
        } else {
            auction.finished = true;
        }
    }

  //  Phase V

    function announceWinner() public onlyAuctioneer afterEnrollmentWindow afterFinished{
        winner = currentBidder;
    }

    function payRemainder() public payable onlyWinner afterFinished{

        (bool sent,  ) =  auctioneer.call{value: ((currentBid - auction.collateral) * 1000000000000000000)}("");
        require(sent, "Failed to send Ether");

    }

    function repayCollateral(address payable _loser) public payable onlyAuctioneer afterFinished{
        (bool sent,  ) =  _loser.call{value: (auction.collateral * 1000000000000000000)}("");
        require(sent, "Failed to send Ether");

    }


}
