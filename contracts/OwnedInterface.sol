pragma solidity ^0.4.8;

contract OwnedInterface {
   function claimContractOwnership() returns(bool);
   function changeContractOwnership(address _to) returns(bool);
}
