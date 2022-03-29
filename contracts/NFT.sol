//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MDDA.sol";

/*

MDDA constructor

DA_STARTING_PRICE = 0.5 ether
DA_ENDING_PRICE = 0.1 ether
DA_DECREMENT = 0.05 ether
DA_DECREMENT_FREQUENCY = 180 seconds
DA_STARTING_TIMESTAMP = 1648080000 UNIX
DA_MAX_QUANTITY = 5
DA_QUANTITY = 7000

*/


contract NFT is Ownable, ERC721A, MDDA {
    constructor()
        ERC721A("NFT", "NFT")
        MDDA(0.5 ether, 0.1 ether, 0.05 ether, 180, 0, 5, 7000)
    {}

    function mintDutchAuction(uint8 _quantity) public payable {
        DAHook(_quantity, totalSupply());

        //Mint the quantity
        _safeMint(msg.sender, _quantity);
    }
}
