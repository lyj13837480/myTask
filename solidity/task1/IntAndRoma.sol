// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract IntAndRoma{
    uint256[] private  values =[0,1000,900,500,400,100,90,50,40,10,9,5,4,1];
    string[] private str = ["","M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"];
    
    //数字转罗马
    function intToRoma(uint256 _int) public view  returns(string memory){
        string memory res;

        for (uint i=0;i<13;i++){
            if(_int >= values[i]){
                string memory s = str[i];
                bytes memory b = abi.encodePacked(res,s);
                res = string(b);
                _int -= values[i];
            }else {
                ++i;
            }
        }
        return res;
    }

    //罗马转数字
    function romaToInt(string memory s)public pure returns ( uint256){
        uint i = 0;
        uint res = 0;
        bytes memory b = bytes(s);
        while(i < b.length-1){
            uint256 num1 = getNum(b[i]);
            uint256 num2 = getNum(b[i+1]);
            if(num1 >= num2){
                res += num1;
                i++;
            }else{
                res += num2 - num1;
                i+=2;
            }
        }
        if(i == b.length-1){
            res += getNum(b[i]);
        }
        return res;
    }

    function getNum(bytes32 b) private  pure returns(uint256){
        if(b == 'I'){
            return 1;
        }else if(b == 'V'){
            return 5;
        }else if(b == 'X'){
            return 10;
        }else if(b == 'L'){
            return 50;
        }else if(b == 'C'){
            return 100;
        }else if(b == 'D'){
            return 500;
        }else if(b == 'M'){
            return 1000;
        }
        return 0;
    }
    
}