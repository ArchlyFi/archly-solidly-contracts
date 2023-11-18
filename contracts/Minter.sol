// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IUnderlying} from "./interfaces/IUnderlying.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IVotingEscrowDistributor} from "./interfaces/IVotingEscrowDistributor.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract Minter {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint public emission = 9900;
    uint public tail_emission = 100;
    uint internal constant target_base = 10000; // 1% per week target emission
    uint internal constant tail_base = 10000; // 1% per week target emission
    IUnderlying public immutable _token;
    IVoter public immutable _voter;
    IVotingEscrow public immutable _ve;
    IVotingEscrowDistributor public immutable _ve_dist;
    uint public weekly = 50000e18;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public team;
    address public pendingTeam;
    uint public teamRate;
    uint public rebaseRate;
    uint public constant MAX_TEAM_RATE = 100; // 100 bps = 10%
    uint public constant MAX_REBASE_RATE = 1000; // 1000 bps = 100%
    
    address[] internal excludedAddresses;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address  __ve, // the ve(3,3) system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        team = 0x0c5D52630c982aE81b78AB2954Ddc9EC2797bB9c;
        teamRate = 50; // 50 bps = 5%
        rebaseRate = 1000; // 1000 bps = 100%
        _token = IUnderlying(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _ve_dist = IVotingEscrowDistributor(__ve_dist);
        active_period = ((block.timestamp + (2 * week)) / week) * week;
    }

    function initialize(
        address[] memory claimants,
        uint[] memory amounts,
        uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        _token.approve(address(_ve), type(uint).max);
        for (uint i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], lock, claimants[i]);
        }
        initializer = address(0);
        active_period = (block.timestamp / week) * week;
    }
    
    function getExcludedAddresses() public view returns (address[] memory) {
        return excludedAddresses;
    }
    
    function setExcludedAddresses(address[] memory _excludedAddresses) public {
        require(msg.sender == _voter.admin(), "not voter admin");
        excludedAddresses = _excludedAddresses;
    }

    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setTeamRate(uint _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }
    
    function setRebaseRate(uint _rebaseRate) external {
        require(msg.sender == _voter.admin(), "not voter admin");
        require(_rebaseRate <= MAX_REBASE_RATE, "rate too high");
        rebaseRate = _rebaseRate;
    }
    
    function setTailEmission(uint _tailEmission) external {
        require(msg.sender == _voter.admin(), "not voter admin");
        require(_tailEmission <= tail_base, "tail emission is too high");
        tail_emission = _tailEmission;
    }

    function setEmission(uint _emission) external {
        require(msg.sender == _voter.admin(), "not voter admin");
        require(_emission <= target_base, "emission is too high");
        emission = _emission;
    }
    
    // calculates sum of all balances for excluded addresses
    function excluded_circulating_supply() internal view returns (uint excludedCirculatingSupply) {
        for (uint i = 0; i < excludedAddresses.length; i++) {
            excludedCirculatingSupply += _token.balanceOf(excludedAddresses[i]);
        }
        
        return excludedCirculatingSupply;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return (_token.totalSupply() - excluded_circulating_supply()) - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / (_token.totalSupply() - excluded_circulating_supply());
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        return rebaseRate * (_ve.totalSupply() * _minted / (_token.totalSupply() - excluded_circulating_supply())) / MAX_REBASE_RATE;
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = block.timestamp / week * week;
            active_period = _period;
            weekly = weekly_emission();

            uint _growth = calculate_growth(weekly);
            uint _teamEmissions = (teamRate * (_growth + weekly)) / 1000;
            uint _required = _growth + weekly + _teamEmissions;
            uint _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required - _balanceOf);
            }

            if(_teamEmissions > 0) {
                require(_token.transfer(team, _teamEmissions));
            }
            
            if(_growth > 0) {
                require(_token.transfer(address(_ve_dist), _growth));
                _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
                _ve_dist.checkpoint_total_supply(); // checkpoint supply
            }
            
            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }
}
