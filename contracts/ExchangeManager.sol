pragma solidity ^0.4.11;

import "./Managed.sol";
import "./Exchange.sol";
//import "./KrakenPriceTicker.sol";
import {ERC20ManagerInterface as ERC20Manager} from "./ERC20ManagerInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import {ContractsManagerInterface as ContractsManager} from "./ContractsManagerInterface.sol";
import "./ExchangeManagerEmitter.sol";

contract ExchangeManager is Managed, ExchangeManagerEmitter {
  // Exchange Manager errors
    uint constant ERROR_EXCHANGE_STOCK_NOT_FOUND = 7000;
    uint constant ERROR_EXCHANGE_STOCK_INVALID_PARAMETER = 7001;
    uint constant ERROR_EXCHANGE_STOCK_INVALID_INVOCATION = 7002;
    uint constant ERROR_EXCHANGE_STOCK_ADD_CONTRACT = 7003;
    uint constant ERROR_EXCHANGE_STOCK_UNABLE_CREATE_EXCHANGE = 7004;

    address[] public exchanges;
    mapping (address => address[]) owners;

    //Exchanges APIs for rate tracking array
    //string[] public URLs;
    //mapping(bytes32 => bool) URLexsist;

    modifier onlyExchangeOwner(address _exchange) {
        if (isExchangeOwner(_exchange, msg.sender)) {
            _;
        }
    }

    function isExchangeOwner(address _exchange, address _owner) constant returns (bool) {
        for (uint i = 0; i < owners[_exchange].length; i++) {
            if (owners[_exchange][i] == _owner) {return true;}
        }
        return false;
    }

    function ExchangeManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {

    }

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return ERROR_EXCHANGE_STOCK_INVALID_INVOCATION;
        }

        uint e = ContractsManagerInterface(_contractsManager)
                  .addContract(this, bytes32("ExchangeManager"));
        if (OK != e) {
            return ERROR_EXCHANGE_STOCK_ADD_CONTRACT;
        }

        store.set(contractsManager, _contractsManager);
        return OK;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_EXCHANGE_STOCK_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);

        return OK;
    }

    function forward(address _exchange, bytes data) onlyExchangeOwner(_exchange) returns (uint errorCode) {
        if (!Exchange(_exchange).call(data)) {
            throw;
        }

        errorCode = OK;
    }

    function addExchange(address _exchange) returns (uint errorCode) {
        Exchange(_exchange).buyPrice();
        Exchange(_exchange).sellPrice();
        if (owners[_exchange].length == 0) {
            exchanges.push(_exchange);
            owners[_exchange].push(msg.sender);
            _emitExchangeAdded(msg.sender, _exchange, exchanges.length);
            errorCode = OK;
        } else {
            errorCode = _emitError(ERROR_EXCHANGE_STOCK_INVALID_PARAMETER);
        }
    }

    function editExchange(address _exchangeOld, address _exchangeNew) onlyExchangeOwner(_exchangeOld) returns (uint errorCode) {
        for (uint i = 0; i < exchanges.length; i++) {
            if (exchanges[i] == _exchangeOld) {
                exchanges[i] = _exchangeNew;
                exchanges.length -= 1;
                _emitExchangeEdited(msg.sender, _exchangeOld, _exchangeNew);
                return OK;
            }
        }

        errorCode = _emitError(ERROR_EXCHANGE_STOCK_NOT_FOUND);
    }

    function removeExchange(address _exchange) onlyExchangeOwner(_exchange) returns (uint errorCode) {
        for (uint i = 0; i < exchanges.length; i++) {
            if (exchanges[i] == _exchange) {
                exchanges[i] = exchanges[exchanges.length - 1];
                exchanges.length -= 1;
                break;
            }
        }
        delete owners[_exchange];
        _emitExchangeRemoved(msg.sender, _exchange);
        return OK;
    }

    function createExchange(bytes32 _symbol, bool _useTicker) returns (uint errorCode) {
        address _contractsManager = store.get(contractsManager);
        address _erc20Manager = ContractsManager(_contractsManager).getContractAddressByType(bytes32("ERC20Manager"));
        address tokenAddr = ERC20Manager(_erc20Manager).getTokenAddressBySymbol(_symbol);
        address rewards = ContractsManager(_contractsManager).getContractAddressByType(bytes32("Rewards"));

        if (tokenAddr == 0x0 || rewards == 0x0) {
            return _emitError(ERROR_EXCHANGE_STOCK_UNABLE_CREATE_EXCHANGE);
        }

        address exchangeAddr = new Exchange();
        address tickerAddr;
        if (_useTicker) {
            //address tickerAddr = new KrakenPriceTicker();
        }

        Exchange(exchangeAddr).init(Asset(tokenAddr), rewards, tickerAddr, 10);
        exchanges.push(exchangeAddr);
        owners[exchangeAddr].push(msg.sender);

        _emitExchangeCreated(msg.sender, exchangeAddr, exchanges.length);
        errorCode = OK;
    }

    function addExchangeOwner(address _exchange, address _owner) onlyExchangeOwner(_exchange) returns (uint errorCode) {
        for (uint i = 0; i < owners[_exchange].length; i++) {
            if (owners[_exchange][i] == _owner) {
                return _emitError(ERROR_EXCHANGE_STOCK_INVALID_PARAMETER);
            }
        }
        owners[_exchange].push(_owner);
        _emitExchangeOwnerAdded(msg.sender, _owner, _exchange);
        return OK;
    }

    function removeExchangeOwner(address _exchange, address _owner) onlyExchangeOwner(_exchange) returns (uint errorCode) {
        if (_owner == msg.sender) {
            return _emitError(ERROR_EXCHANGE_STOCK_INVALID_PARAMETER);
        }

        for (uint i = 0; i < owners[_exchange].length; i++) {
            if (owners[_exchange][i] == _owner) {
                owners[_exchange][i] = owners[_exchange][owners[_exchange].length - 1];
                owners[_exchange].length--;
                _emitExchangeOwnerRemoved(msg.sender, _owner, _exchange);
                return OK;
            }
        }

        errorCode = _emitError(ERROR_EXCHANGE_STOCK_NOT_FOUND);
    }

    function getExchangeOwners(address _exchange) constant returns (address[]) {
        return owners[_exchange];
    }

    function getExchangesForOwner(address owner) constant returns (address[]) {
        uint counter;
        uint i;
        for (i = 0; i < exchanges.length; i++) {
            if (isExchangeOwner(exchanges[i], owner))
            counter++;
        }
        address[] memory result = new address[](counter);
        counter = 0;
        for (i = 0; i < exchanges.length; i++) {
            if (isExchangeOwner(exchanges[i], owner)) {
                result[counter] = exchanges[i];
                counter++;
            }
        }
        return result;
    }

    function _emitExchangeRemoved(address user, address exchange) internal {
        ExchangeManager(getEventsHistory()).emitExchangeRemoved(user, exchange);
    }

    function _emitExchangeAdded(address user, address exchange, uint count) internal {
        ExchangeManager(getEventsHistory()).emitExchangeAdded(user, exchange, count);
    }

    function _emitExchangeEdited(address user, address oldExchange, address newExchange) internal {
        ExchangeManager(getEventsHistory()).emitExchangeEdited(user, oldExchange, newExchange);
    }

    function _emitExchangeCreated(address user, address exchange, uint count) internal {
        ExchangeManager(getEventsHistory()).emitExchangeCreated(user, exchange, count);
    }

    function _emitExchangeOwnerAdded(address user, address owner, address exchange) internal {
        ExchangeManager(getEventsHistory()).emitExchangeOwnerAdded(user, owner, exchange);
    }

    function _emitExchangeOwnerRemoved(address user, address owner, address exchange) internal {
        ExchangeManager(getEventsHistory()).emitExchangeOwnerRemoved(user, owner, exchange);
    }

    function _emitError(uint error) internal returns (uint) {
        ExchangeManager(getEventsHistory()).emitError(error);
        return error;
    }
}
