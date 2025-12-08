// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Sum {
    uint public sum;
    function add() public  returns (uint) {
        sum++;
        return sum;
    }
}