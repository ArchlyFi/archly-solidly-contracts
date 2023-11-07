// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IVotingEscrowDistributor {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}