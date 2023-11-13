// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IArc} from "./interfaces/IArc.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";

contract ArcMigrator is Ownable2Step, Pausable, ReentrancyGuard, IERC721Receiver {
    
    IArc fromArc;
    IVotingEscrow fromVeArc;
    
    IArc toArc;
    IVotingEscrow toVeArc;
    
    event ArcMigrated(address indexed account, uint amount);
    event VeArcMigrated(address indexed account, uint fromTokenId, uint toTokenId, uint amount, uint fromLockEnd, uint toLockEnd);
    event VeArcReceived(address indexed operator, address indexed from, uint tokenId, bytes data);
    
    constructor(address _fromArc, address _fromVeArc, address _toArc, address _toVeArc) {
        require(_fromArc != address(0) && _fromVeArc != address(0) && _toArc != address(0) && _toVeArc != address(0), 'Zero address passed in constructor');
        
        fromArc = IArc(_fromArc);
        fromVeArc = IVotingEscrow(_fromVeArc);
        
        toArc = IArc(_toArc);
        toVeArc = IVotingEscrow(_toVeArc);
    }
    
    function pause() public onlyOwner
    {
        _pause();
    }
    
    function unpause() public onlyOwner
    {
        _unpause();
    }
    
    function migrateArc() external nonReentrant whenNotPaused {
        uint balance = fromArc.balanceOf(msg.sender);
        fromArc.transferFrom(msg.sender, address(this), balance);
        fromArc.burn(balance);
        
        toArc.mint(msg.sender, balance);
        emit ArcMigrated(msg.sender, balance);
    }
    
    function migrateVeArc(uint tokenId) external nonReentrant whenNotPaused {
        uint lockedAmount = fromVeArc.locked__amount(tokenId);
        uint lockedEnd = fromVeArc.locked__end(tokenId);
        fromVeArc.safeTransferFrom(msg.sender, address(this), tokenId);
        fromVeArc.burn(tokenId);
        
        uint blockTimestamp = block.timestamp;
        uint newLockDuration = lockedEnd - blockTimestamp;
        
        toArc.mint(address(this), lockedAmount);
        toArc.approve(address(toVeArc), lockedAmount);
        uint newTokenId = toVeArc.create_lock_for(lockedAmount, newLockDuration, msg.sender);
        emit VeArcMigrated(msg.sender, tokenId, newTokenId, lockedAmount, lockedEnd, newLockDuration + blockTimestamp);
    }
    
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4) {
        emit VeArcReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
}