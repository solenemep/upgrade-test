// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./Upgrader.sol";
import "./interfaces/IRegistry.sol";
import "./abstract/AbstractDependant.sol";

contract Registry is IRegistry, AccessControlUpgradeable {
    Upgrader internal _upgrader;

    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant STORAGE_NAME = keccak256("STORAGE");

    mapping(bytes32 => address) private _contracts;
    mapping(address => bool) private _isProxy;

    modifier onlyAdmin() {
        require(hasRole(REGISTRY_ADMIN_ROLE, msg.sender), "Registry: Caller is not an admin");
        _;
    }

    function initRegistry() external initializer {
        __AccessControl_init();

        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);

        _upgrader = new Upgrader();
    }

    function getStorageContract() external view override returns (address) {
        return getContract(STORAGE_NAME);
    }

    function getContract(bytes32 name) public view returns (address) {
        require(_contracts[name] != address(0), "Registry.getContract: This mapping doesn't exist");

        return _contracts[name];
    }

    function hasContract(bytes32 name) external view returns (bool) {
        return _contracts[name] != address(0);
    }

    function injectDependencies(bytes32 name) external onlyAdmin {
        address contractAddress = _contracts[name];

        require(contractAddress != address(0), "Registry.injectDependencies: This mapping doesn't exist");

        AbstractDependant dependant = AbstractDependant(contractAddress);

        if (dependant.injector() == address(0)) {
            dependant.setInjector(address(this));
        }

        dependant.setDependencies(this);
    }

    function getUpgrader() external view returns (address) {
        require(address(_upgrader) != address(0), "Registry: Bad upgrader");

        return address(_upgrader);
    }

    function getImplementation(bytes32 name) external returns (address) {
        address contractProxy = _contracts[name];

        require(contractProxy != address(0), "Registry.getImplementation: This mapping doesn't exist");
        require(_isProxy[contractProxy], "Registry: Not a proxy contract");

        return _upgrader.getImplementation(contractProxy);
    }

    function upgradeContract(bytes32 name, address newImplementation) external onlyAdmin {
        _upgradeContract(name, newImplementation, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradeContractAndCall(
        bytes32 name,
        address newImplementation,
        string calldata functionSignature
    ) external onlyAdmin {
        _upgradeContract(name, newImplementation, functionSignature);
    }

    function _upgradeContract(
        bytes32 name,
        address newImplementation,
        string memory functionSignature
    ) internal {
        address contractToUpgrade = _contracts[name];

        require(contractToUpgrade != address(0), "Registry._upgradeContract: This mapping doesn't exist");
        require(_isProxy[contractToUpgrade], "Registry: Not a proxy contract");

        if (bytes(functionSignature).length > 0) {
            _upgrader.upgradeAndCall(contractToUpgrade, newImplementation, abi.encodeWithSignature(functionSignature));
        } else {
            _upgrader.upgrade(contractToUpgrade, newImplementation);
        }
    }

    function addContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "Registry: Null address is forbidden");

        _contracts[name] = contractAddress;
    }

    function addProxyContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "Registry: Null address is forbidden");

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(contractAddress, address(_upgrader), "");

        _contracts[name] = address(proxy);
        _isProxy[address(proxy)] = true;
    }

    function justAddProxyContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "Registry: Null address is forbidden");

        _contracts[name] = contractAddress;
        _isProxy[contractAddress] = true;
    }

    function deleteContract(bytes32 name) external onlyAdmin {
        require(_contracts[name] != address(0), "Registry.deleteContract: This mapping doesn't exist");

        delete _isProxy[_contracts[name]];
        delete _contracts[name];
    }
}
