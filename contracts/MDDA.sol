//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/*

Open source Dutch Auction contract

Dutch Auction that exposes a function to minters that allows them to pull difference between payment price and settle price.

Initial version has no owner functions to not allow for owner foul play.

Written by: mousedev.eth

Modified by: @NftDoyler
    Made the withdrawal methods virtual, to allow for custom withdraws.

*/

contract MDDA is Ownable {
    uint256 public DA_STARTING_PRICE;

    uint256 public DA_ENDING_PRICE;

    uint256 public DA_DECREMENT;

    uint256 public DA_DECREMENT_FREQUENCY;

    uint256 public DA_STARTING_TIMESTAMP;

    uint256 public DA_MAX_QUANTITY;

    //The price the auction ended at.
    uint256 public DA_FINAL_PRICE;

    //The quantity for DA.
    uint256 public DA_QUANTITY;

    bool public DATA_SET;

    bool public INITIAL_FUNDS_WITHDRAWN;

    //Struct for storing batch price data.
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint128 quantityMinted;
    }

    //Token to token price data
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    function initializeAuctionData(
        uint256 _DAStartingPrice,
        uint256 _DAEndingPrice,
        uint256 _DADecrement,
        uint256 _DADecrementFrequency,
        uint256 _DAStartingTimestamp,
        uint256 _DAMaxQuantity,
        uint256 _DAQuantity
    ) public onlyOwner {
        require(!DATA_SET, "DA data has already been set.");
        DA_STARTING_PRICE = _DAStartingPrice;
        DA_ENDING_PRICE = _DAEndingPrice;
        DA_DECREMENT = _DADecrement;
        DA_DECREMENT_FREQUENCY = _DADecrementFrequency;
        DA_STARTING_TIMESTAMP = _DAStartingTimestamp;
        DA_MAX_QUANTITY = _DAMaxQuantity;
        DA_QUANTITY = _DAQuantity;

        DATA_SET = true;
    }

    function userToTokenBatches(address user)
        public
        view
        returns (TokenBatchPriceData[] memory)
    {
        return userToTokenBatchPriceData[user];
    }

    function currentPrice() public view returns (uint256) {
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        //Seconds since we started
        uint256 timeSinceStart = block.timestamp - DA_STARTING_TIMESTAMP;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;

        //How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return DA_STARTING_PRICE - totalDecrement;
    }

    function DAHook(uint128 _quantity, uint256 _totalSupply) internal {
        require(DATA_SET, "DA data not set yet");

        uint256 _currentPrice = currentPrice();

        //Require enough ETH
        require(
            msg.value >= _quantity * _currentPrice,
            "Did not send enough eth."
        );

        require(
            _quantity > 0 && _quantity <= DA_MAX_QUANTITY,
            "Incorrect quantity!"
        );

        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );

        require(
            _totalSupply + _quantity <= DA_QUANTITY,
            "Max supply for DA reached!"
        );

        //Set the final price.
        if (_totalSupply + _quantity == DA_QUANTITY)
            DA_FINAL_PRICE = _currentPrice;

        //Add to user batch array.
        userToTokenBatchPriceData[msg.sender].push(
            TokenBatchPriceData(uint128(msg.value), _quantity)
        );
    }

    function refundExtraETH() public {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 totalRefund;

        for (
            uint256 i = userToTokenBatchPriceData[msg.sender].length;
            i > 0;
            i--
        ) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = userToTokenBatchPriceData[msg.sender][i - 1]
                .quantityMinted * DA_FINAL_PRICE;

            //What they paid - what they should have paid = refund.
            uint256 refund = userToTokenBatchPriceData[msg.sender][i - 1]
                .pricePaid - expectedPrice;

            //Remove this tokenBatch
            userToTokenBatchPriceData[msg.sender].pop();

            //Send them their extra monies.
            totalRefund += refund;
        }
        payable(msg.sender).transfer(totalRefund);
    }

    function withdrawInitialFunds() public virtual onlyOwner initialWithdraw {
        //Only pull the amount of ether that is the final price times how many were bought. This leaves room for refunds until final withdraw.
        uint256 initialFunds = DA_QUANTITY * DA_FINAL_PRICE;

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(msg.sender).call{value: initialFunds}("");

        require(succ, "transfer failed");
    }

    function withdrawFinalFunds() public virtual onlyOwner finalWithdraw {
        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(msg.sender).call{value: finalFunds}("");
        require(succ, "transfer failed");
    }

    modifier initialWithdraw {
        require(!INITIAL_FUNDS_WITHDRAWN, "Initial funds already withdrawn.");
        require(DA_FINAL_PRICE > 0, "DA hasn't finished");
        _;
    }

    modifier finalWithdraw {
        //Require this is 1 week after DA Start.
        require(block.timestamp >= DA_STARTING_TIMESTAMP + 604800);
        _;
    }
}
