pragma solidity ^0.4.11;

contract ContractsManagerInterface {
    function getContractAddressByType(bytes32 _type) constant returns (address contractAddress);
    function addContract(address _contractAddr, bytes32 _type) returns (uint);
}
