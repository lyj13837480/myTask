// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNft is ERC721Enumerable, Ownable {
    constructor(
        string memory name_
    ) ERC721(name_, "MNFT") Ownable(msg.sender) {}

    //铸造方法
    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    //重写baseURI方法
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }
}
