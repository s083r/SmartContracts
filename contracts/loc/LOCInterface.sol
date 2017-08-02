pragma solidity ^0.4.11;

contract LOCInterface {
  function getContractOwner() constant returns(address);
  function getIssued() constant returns(uint);
  function getIssueLimit() constant returns(uint);
}
