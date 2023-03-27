// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './BribeV2.sol';

contract BaseV1BribeV2Factory {
    address public immutable voter;
    mapping(address => address) public bribeV1ToV2;
    address public last_bribe;

    constructor(address _voter) {
        voter = _voter;
    }

    function createBribe(address existing_bribe) external returns (address) {
        require(
            bribeV1ToV2[existing_bribe] == address(0),
            "V2 bribe already created"
        );
        
        last_bribe = address(new BribeV2(voter, existing_bribe));
        bribeV1ToV2[existing_bribe] = last_bribe;
        return last_bribe;
    }
}