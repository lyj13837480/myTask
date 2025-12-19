// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNftToken is ERC721,Ownable {
    uint256 tokenId;
    constructor() ERC721("MyNftToken", "MNT") Ownable(msg.sender) {
    }

    function mint() payable public {
        require(msg.value >= 0.01 ether, "Not enough ether");
        _mint(msg.sender, tokenId);
        tokenId++;
    }

}