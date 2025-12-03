// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BeggingContract{
    mapping (address donate => uint256 value) donates;
    address private owner;
    event Donation(address sender, uint amount);//记录日志
    address[3] top3;
    uint public startTime = block.timestamp + 3600; // 1小时后
    uint public endTime = block.timestamp + 7200; // 2小时后

   
    //event FallbackCalled(address sender, uint amount, bytes data);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner,"you are not owner");
        _;
    }

    function donate()external payable  returns (bool){
        require(msg.value > 0,"value must great than zero");
        //require(block.timestamp > startTime && block.timestamp <= endTime);
        donates[msg.sender] += msg.value;
        emit Donation(msg.sender,msg.value);
        topN();
        return true;
    }

    function getDonation(address donate_) external view  returns (uint256){
        return donates[donate_];
    }

    function withdraw() external payable onlyOwner returns (bool) {
        require(address(this).balance > 0,"balance must great than zero");
        payable(owner).transfer(address(this).balance);
        return true;
    }

    function topN() private {
        address addr = msg.sender;
        for (uint8 i = 0; i < top3.length;i++) {
            if (donates[addr] > donates[top3[i]]){
                address temp = addr;
                addr = top3[i];
                top3[i] = temp;
            }
        }
    }

    function getTopN() external view  returns (address[3] memory){
        return top3;
    }


    // receive() external payable { 
    //     emit Received(msg.sender,msg.value);
    // }

    // fallback() external payable { 
    //     emit FallbackCalled(msg.sender, msg.value, msg.data);
    // }
}