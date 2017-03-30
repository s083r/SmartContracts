pragma solidity ^0.4.8;

contract FeeInterface {
    // Fee collecting address, immutable.
    address public feeAddress;

    // Fee percent, immutable. 1 is 0.01%, 10000 is 100%.
    uint32 public feePercent;

    function calculateFee(uint _value) returns(uint);
}
