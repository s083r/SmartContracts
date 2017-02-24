pragma solidity ^0.4.8;

contract ChronoBankPlatformInterface {
/**
     * Returns asset balance for a particular holder id.
     *
     * @param _holderId holder id.
     * @param _symbol asset symbol.
     *
     * @return holder balance.
     */
    function _balanceOf(uint _holderId, bytes32 _symbol) returns(uint);

    /**
     * Returns current address for a particular holder id.
     *
     * @param _holderId holder id.
     *
     * @return holder address.
     */
    function _address(uint _holderId) returns(address); 

    function reissueAsset(bytes32 _symbol, uint _value) returns(bool);
}
