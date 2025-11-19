// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Merge{

    function merge(int[] memory s1,int[] memory s2) public pure returns (int[] memory){
        int[] memory result = new int[](s1.length + s2.length);
        uint i1 = 0;
        uint i2 = 0;
        while (i1 < s1.length && i2 < s2.length){
            if (s1[i1] <= s2[i2]){
                result[i1 + i2] = s1[i1];
                i1++;
            } else {
                result[i1 + i2] = s2[i2];
                i2++;
            }
        }
        while (i1 < s1.length){
            result[i1 + i2] = s1[i1];
            i1++;
        }
        while (i2 < s2.length){
            result[i1 + i2] = s2[i2];
            i2++;       
        }
        
        return result;            
    }

}