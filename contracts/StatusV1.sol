//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IStatusV1.sol";
import "./abstract/AbstractDependant.sol";

contract StatusV1 is IStatusV1, OwnableUpgradeable, AbstractDependant {
    string private _data;

    event DataSet(address indexed account, string data1);

    function initStatus(string memory data_) external initializer {
        _data = data_;
    }

    function setDependencies(IRegistry _registry) external override onlyInjectorOrZero {}

    function setData(string memory data_) public {
        _data = data_;
        emit DataSet(msg.sender, data_);
    }

    function getData() public view returns (string memory) {
        return _data;
    }
}
