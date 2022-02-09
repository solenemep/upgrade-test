// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

interface IRegistry {
    function getStorageContract() external view returns (address);
}
