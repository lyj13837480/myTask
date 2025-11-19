// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract revStr{

    function reverseString(string memory str) public pure returns (string memory) {
        bytes memory rev = bytes(str);
        for (uint i=0;i < rev.length/2;i++){
            bytes1 temp = rev[i];
            rev[i] = rev[rev.length-i-1];
            rev[rev.length-i-1] = temp;
        }
        return string(rev);
    }
}