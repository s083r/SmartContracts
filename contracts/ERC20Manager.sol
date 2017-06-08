pragma solidity ^0.4.11;

import "./Managed.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import "./ERC20ManagerEmitter.sol";

contract ERC20Manager is Managed, ERC20ManagerEmitter {

    event LogAddToken(
    address token,
    bytes32 name,
    bytes32 symbol,
    bytes32 url,
    uint8 decimals,
    bytes32 ipfsHash,
    bytes32 swarmHash
    );

    event LogRemoveToken(
    address token,
    bytes32 name,
    bytes32 symbol,
    bytes32 url,
    uint8 decimals,
    bytes32 ipfsHash,
    bytes32 swarmHash
    );

    event LogTokenNameChange(address token, bytes32 oldName, bytes32 newName);
    event LogTokenSymbolChange(address token, bytes32 oldSymbol, bytes32 newSymbol);
    event LogTokenUrlChange(address token, bytes32 oldUrl, bytes32 newUrl);
    event LogTokenIpfsHashChange(address token, bytes32 oldIpfsHash, bytes32 newIpfsHash);
    event LogTokenSwarmHashChange(address token, bytes32 oldSwarmHash, bytes32 newSwarmHash);

    StorageInterface.AddressesSet tokenAddresses;
    StorageInterface.Bytes32AddressMapping tokenBySymbol;
    StorageInterface.AddressBytes32Mapping name;
    StorageInterface.AddressBytes32Mapping symbol;
    StorageInterface.AddressBytes32Mapping url;
    StorageInterface.AddressBytes32Mapping ipfsHash;
    StorageInterface.AddressBytes32Mapping swarmHash;
    StorageInterface.AddressUIntMapping decimals;

    modifier tokenExists(address _token) {
        if (store.includes(tokenAddresses,_token)) {
            _;
        }
    }

    modifier tokenSymbolExists(bytes32 _symbol) {
        if (store.get(tokenBySymbol,_symbol) != address(0)) {
            _;
        }
    }

    modifier tokenDoesNotExist(address _token) {
        if (!store.includes(tokenAddresses,_token)) {
            _;
        }
    }

    modifier tokenSymbolDoesNotExists(bytes32 _symbol) {
        if (store.get(tokenBySymbol,_symbol) == address(0)) {
            _;
        }
    }

    function ERC20Manager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        tokenAddresses.init('tokenAddresses');
        tokenBySymbol.init('tokeBySymbol');
        name.init('name');
        symbol.init('symbol');
        url.init('url');
        ipfsHash.init('ipfsHash');
        swarmHash.init('swarmHash');
        decimals.init('decimals');
    }

    function init(address _contractsManager) returns(bool) {
        if(store.get(contractsManager) != 0x0)
            return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.ERC20Manager))
            return false;
        store.set(contractsManager,_contractsManager);
        return true;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns(bool) {
        if (getEventsHistory() != 0x0) {
            return false;
        }
        _setEventsHistory(_eventsHistory);
        return true;
    }

    /// @dev Allows owner to add a new token to the registry.
    /// @param _token Address of new token.
    /// @param _name Name of new token.
    /// @param _symbol Symbol for new token.
    /// @param _url Token's project URL.
    /// @param _decimals Number of decimals, divisibility of new token.
    /// @param _ipfsHash IPFS hash of token icon.
    /// @param _swarmHash Swarm hash of token icon.
    function addToken(
    address _token,
    bytes32 _name,
    bytes32 _symbol,
    bytes32 _url,
    uint8 _decimals,
    bytes32 _ipfsHash,
    bytes32 _swarmHash)
    tokenSymbolDoesNotExists(_symbol)
    tokenDoesNotExist(_token)
    returns(bool)
    {
        Asset(_token).totalSupply();
        store.add(tokenAddresses,_token);
        store.set(tokenBySymbol,_symbol,_token);
        store.set(name,_token,_name);
        store.set(symbol,_token,_symbol);
        store.set(url,_token,_url);
        store.set(decimals,_token,_decimals);
        store.set(ipfsHash,_token,_ipfsHash);
        store.set(swarmHash,_token,_swarmHash);

        LogAddToken(
        _token,
        _name,
        _symbol,
        _url,
        _decimals,
        _ipfsHash,
        _swarmHash
        );
        return true;
    }

    function setToken(
    address _token,
    address _newToken,
    bytes32 _name,
    bytes32 _symbol,
    bytes32 _url,
    uint8 _decimals,
    bytes32 _ipfsHash,
    bytes32 _swarmHash)
    public
    onlyAuthorized
    tokenExists(_token) returns(bool)
    {
        bool changed;
        if(_symbol != store.get(symbol,_token)) {
            if (store.get(tokenBySymbol,_symbol) == address(0)) {
                store.set(tokenBySymbol,store.get(symbol,_token),address(0));
                if(_token != _newToken) {
                    store.set(tokenBySymbol,_symbol,_newToken);
                    store.set(symbol,_newToken,_symbol);
                } else {
                    store.set(tokenBySymbol,_symbol,_token);
                    store.set(symbol,_token,_symbol);
                }
                changed = true;
            } else {
                return false;
            }
        }
        if(_token != _newToken) {
            Asset(_newToken).totalSupply();
            store.set(tokenAddresses,_token,_newToken);
            if(!changed) {
                store.set(tokenBySymbol,_symbol,_newToken);
                store.set(symbol,_newToken,_symbol);
            }
            store.set(name,_newToken,_name);
            store.set(url,_newToken,_url);
            store.set(decimals,_newToken,_decimals);
            store.set(ipfsHash,_newToken,_ipfsHash);
            store.set(swarmHash,_newToken,_swarmHash);
            _token = _newToken;
            changed = true;
        }

        if(store.get(name,_token) != _name) {
            store.set(name,_token,_name);
            changed = true;
        }

        if(store.get(decimals,_token) != _decimals) {
            store.set(decimals,_token,_decimals);
            changed = true;
        }
        if(store.get(url,_token) != _url) {
            store.set(url,_token,_url);
            changed = true;
        }
        if(store.get(ipfsHash,_token) != _ipfsHash) {
            store.set(ipfsHash,_token,_ipfsHash);
            changed = true;
        }
        if(store.get(swarmHash,_token) != _swarmHash) {
            store.set(swarmHash,_token,_swarmHash);
            changed = true;
        }

        if(changed) {
            return true;
        }
        return false;

    }

    /// @dev Allows owner to remove an existing token from the registry.
    /// @param _token Address of existing token.
    function removeToken(address _token)
    onlyAuthorized
    tokenExists(_token) returns(bool)
    {
        return removeTokenInt(_token);
    }

    /// @dev Allows owner to remove an existing token from the registry.
    /// @param _symbol Symbol of existing token.
    function removeTokenBySymbol(bytes32 _symbol)
    onlyAuthorized
    tokenSymbolExists(_symbol) returns(bool)
    {
        return removeTokenInt(store.get(tokenBySymbol,_symbol));
    }

    /// @dev Allows owner to remove an existing token from the registry.
    /// @param _token Address of existing token.
    function removeTokenInt(address _token)
    internal returns(bool)
    {
        LogRemoveToken(
        _token,
        store.get(name,_token),
        store.get(symbol,_token),
        store.get(url,_token),
        uint8(store.get(decimals,_token)),
        store.get(ipfsHash,_token),
        store.get(swarmHash,_token)
        );
        store.set(tokenBySymbol,store.get(symbol,_token),address(0));
        store.remove(tokenAddresses,_token);
        return true;
    }

    /// @dev Provides a registered token's address when given the token symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token's address.
    function getTokenAddressBySymbol(bytes32 _symbol) constant returns (address tokenAddress) {
        return store.get(tokenBySymbol,_symbol);
    }

    /// @dev Provides a registered token's metadata, looked up by address.
    /// @param _token Address of registered token.
    /// @return Token metadata.
    function getTokenMetaData(address _token)
    constant
    tokenExists(_token)
    returns (
    address _tokenAddress,
    bytes32 _name,
    bytes32 _symbol,
    bytes32 _url,
    uint8 _decimals,
    bytes32 _ipfsHash,
    bytes32 _swarmHash
    )
    {
        _name = store.get(name,_token);
        _symbol = store.get(symbol,_token);
        _url = store.get(url,_token);
        _decimals = uint8(store.get(decimals,_token));
        _ipfsHash = store.get(ipfsHash,_token);
        _swarmHash = store.get(swarmHash,_token);
        return (
        _token,
        _name,
        _symbol,
        _url,
        _decimals,
        _ipfsHash,
        _swarmHash
        );
    }

    /// @dev Provides a registered token's metadata, looked up by symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token metadata.
    function getTokenBySymbol(bytes32 _symbol)
    constant
    tokenSymbolExists(_symbol)
    returns (
    address tokenAddress,
    bytes32 name,
    bytes32 symbol,
    bytes32 url,
    uint8 decimals,
    bytes32 ipfsHash,
    bytes32 swarmHash
    )
    {
        address _token = store.get(tokenBySymbol,_symbol);
        return getTokenMetaData(_token);
    }

    /// @dev Returns an array containing all token addresses.
    /// @return Array of token addresses.
    function getTokenAddresses() constant returns (address[]) {
        return store.get(tokenAddresses);
    }

    function _emitError(bytes32 _message) {
        ERC20Manager(getEventsHistory()).emitError(_message);
    }
}