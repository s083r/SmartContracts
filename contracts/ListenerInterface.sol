pragma solidity ^0.4.8;

contract ListenerInterface {
    function deposit(address _address, uint _amount, uint _total) returns (uint);
    function withdrawn(address _address, uint _amount, uint _total) returns (uint);
}
