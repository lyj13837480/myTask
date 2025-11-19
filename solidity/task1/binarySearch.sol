// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.30;

contract BinarySearch{

    function binarySearch(int[] memory arr,int target)public pure returns(int){
        uint start =0;
        uint end = arr.length-1;
        while(start <= end){
            uint mid = (start + end )/2;
            if(target == arr[mid]){
                return int(mid);//返回索引
            }
            if(target < arr[mid]){
                end = mid -1;
            }else{
                start = mid +1;
            }
        }
        return -1;
    }

}