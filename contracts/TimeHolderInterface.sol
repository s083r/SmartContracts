pragma solidity ^0.4.8;

import {ERC20Interface as Asset} from "./ERC20Interface.sol";

contract TimeHolderInterface {

    function totalShares() constant returns (uint);
    function sharesContract() constant returns (address);
    function shareholdersCount() constant returns (uint);
    function totalSupply() constant returns(uint);
    function depositBalance(address _address) constant returns(uint);

}


