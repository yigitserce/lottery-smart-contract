// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0; // version of the solidity

import "@openzeppelin/contracts/access/Ownable.sol"; // Enables the control of important function by owner

contract Lottery is Ownable {
    uint256 public _price = 0.05 ether; // Price 250 SAMA
    address[] public _wallets; // all joined wallets
    address[] public _winnerWallets; // winner wallets
    uint public _total; // total enrollment
    bool public _isLotteryEligible; // to stop lottery after lottery done 
    uint256 public _commissionRate = 10; // owner commission rate in percentage (10%)
    uint randNonce = 0;
    uint _priceInSama = 250; // Price in type of SAMA
    address private _owner;

    constructor() public Ownable() {
        _owner = msg.sender;
    } // Load Ownable Contract functions

    function startLottery() external onlyOwner {
        uint256 totalAmount = (_total * _priceInSama);
        uint awardPool = totalAmount - (totalAmount * (_commissionRate / 100));
        // awardPool is total SAMA without owner commission (90% of total SAMA)
        uint256 winnerCount = 2;
        uint256 payOffRate = 20;
        uint256 payOffCount = ((awardPool * payOffRate / 100) / _priceInSama);
        uint256 loopIterationCount = winnerCount + payOffCount;
        uint i = 0;
        while (i < loopIterationCount) {
            uint256 randomIndex = random();
            address winner = _wallets[randomIndex];
            _winnerWallets.push(winner); 
            i++;
        }

    } // start lottery -> pick random numbers to decide winner's wallets and pay off wallets
      // store winner and pay off wallets in to the winnerWallets variable  

    function random() private returns(uint) {
        randNonce++; 
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _total;
    } // that will generate random number between 0 to total number of ticket

    function join(uint256 numberOfTicket) external payable {
        require(_price*numberOfTicket == msg.value, "Wrong Amount!!");
        require(_isLotteryEligible, "Lottery is not ready yet :)");
        require(numberOfTicket > 0, "Require at least one ticket");
        // check price, lottery eligibility and ticket count conditions 
        
        uint i = 0;
        while(i < numberOfTicket) {
            _wallets.push(msg.sender);
            i++;
            _total++; // increase number of enrollment 
        } // that loop allows you to join with multiple tickets. 
          // For instance, if you buy 5 ticket to join then your wallet adress will be added to pool 5 times. 
          // So, that will up to your chance

    } // each wallet will use this function to join lottery by some of conditions 

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    } // to change price after deploy contract for new types of lotteries
      // NOTE: price will not change during lottery

    function setEligibility() external onlyOwner {
        _isLotteryEligible = !_isLotteryEligible;
    } // stop contract function during gaps between lotteries 

    function getAllWallets() public view returns(address[] memory) {
        return _wallets;
    } // get all joined wallets

    function getAllWinnerWallets() public view returns(address[] memory) {
        return _winnerWallets;
    } // get all winner wallets

    function getEligibility() public view returns(bool) {
        return _isLotteryEligible;
    } // gives lottery eligibility

    function setPriceInSama(uint256 priceInSama) external onlyOwner {
        _priceInSama = priceInSama;
    } // set price with type of sama to calculate number of pay off user

    function transferToWinners() external payable {
        require(msg.sender == _owner, "Only Owner");
        uint256 totalAmount = (_total * _price);
        uint awardPool = totalAmount - (totalAmount * (_commissionRate / 100));
        uint firstWinnerAmount = awardPool * 60 / 100;
        uint secondWinnerAmount = awardPool * 20 / 100;
        uint payOffAmount = _price;

        address firstWinner = _winnerWallets[0];
        address secondWinner = _winnerWallets[1];
        payable(firstWinner).transfer(firstWinnerAmount);
        payable(secondWinner).transfer(secondWinnerAmount);

        uint i = 2;
        while(i < _winnerWallets.length) {
            address payOffWallet = _winnerWallets[i];
            payable(payOffWallet).transfer(payOffAmount);
            i++;
        }

        uint ownerCommissionAmount = totalAmount - awardPool;
        payable(msg.sender).transfer(ownerCommissionAmount);
        
        delete _winnerWallets;
        delete _wallets;
        _total = 0;
        _isLotteryEligible = !_isLotteryEligible;
        randNonce = 0;
    }
}