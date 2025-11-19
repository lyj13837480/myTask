// SPDX-License-Identifier: MIT
pragma solidity ~0.8.30;

contract Vote{
    mapping(string user => uint votes) public userVotes;
    string[] private  keys;
    //投票
    function vote(string memory user) public returns(string memory){
            uint votes = userVotes[user];
            userVotes[user] = votes+1;
            keys.push(user);
            return "success";
    }

    function getVote(string memory user)public view  returns (string memory,uint){
        return (user,userVotes[user]);
    }
    
    //重置所有用户
    function resetVotes()public returns(string memory){
        for (uint i=0;i < keys.length;i++){
            userVotes[keys[i]] = 0;
        }
        return "success";
    }

}