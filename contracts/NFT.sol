//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MDDA.sol";

contract NFT is Ownable, ERC721A, MDDA {
    constructor() ERC721A("NFT", "NFT") {}

    function mintDutchAuction(uint8 _quantity) external payable {
        DAHook(_quantity, totalSupply());

        //Mint the quantity
        _safeMint(msg.sender, _quantity);
    }
}
