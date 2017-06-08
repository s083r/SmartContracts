pragma solidity ^0.4.11;

import {ChronoBankAssetProxy as Proxy} from "./ChronoBankAssetProxy.sol";
import "./ChronoBankAssetWithFee.sol";

contract ProxyFactory {

    function createAsset() returns (address) {
        address asset;
        asset = new ChronoBankAsset();
        return asset;
    }

    function createAssetWithFee() returns (address) {
        address asset;
        asset = new ChronoBankAssetWithFee();
        return asset;
    }

    function createProxy() returns (address) {
        address proxy = new Proxy();
        return proxy;
    }

    function()
    {
        throw;
    }
}
