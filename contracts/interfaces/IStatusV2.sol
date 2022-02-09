// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

interface IStatusV2 {
    enum Status {
        STATUS_KO_0,
        STATUS_OK_0,
        STATUS_KO_1,
        STATUS_OK_1
    }
}
