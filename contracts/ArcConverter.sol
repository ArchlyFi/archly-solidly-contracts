// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IArc} from "./interfaces/IArc.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";

contract ArcConverter is Ownable2Step, Pausable, ReentrancyGuard, IERC721Receiver {
    
    IArc public fromArc;
    IVotingEscrow public fromVeArc;
    
    IArc public toArc;
    IVotingEscrow public toVeArc;
    
    event ArcConverted(address indexed account, uint amount);
    event VeArcConverted(address indexed account, uint fromTokenId, uint toTokenId, uint amount, uint fromLockEnd, uint toLockEnd);
    event VeArcNotConverted(uint tokenId);
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
    
    function withdrawNative(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, 'Unable to withdraw');
    }

    function withdrawToken(address beneficiary, address token) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
    
    function convertArc() external nonReentrant whenNotPaused {
        uint balance = fromArc.balanceOf(msg.sender);
        fromArc.transferFrom(msg.sender, address(this), balance);
        fromArc.burn(balance);
        
        toArc.mint(msg.sender, balance);
        emit ArcConverted(msg.sender, balance);
    }
    
    function _convertVeArc(address account, uint tokenId) public whenNotPaused {
        require(msg.sender == address(this), 'Invalid Caller');
        require(account != address(0), 'Account cannot be zero address');
        
        uint lockedAmount = fromVeArc.locked__amount(tokenId);
        uint lockedEnd = fromVeArc.locked__end(tokenId);
        fromVeArc.safeTransferFrom(account, address(this), tokenId);
        fromVeArc.burn(tokenId);
        
        uint blockTimestamp = block.timestamp;
        uint newLockDuration = lockedEnd - blockTimestamp;
        
        toArc.mint(address(this), lockedAmount);
        toArc.approve(address(toVeArc), lockedAmount);
        uint newTokenId = toVeArc.create_lock_for(lockedAmount, newLockDuration, account);
        emit VeArcConverted(account, tokenId, newTokenId, lockedAmount, lockedEnd, newLockDuration + blockTimestamp);
    }
    
    function convertVeArc(uint tokenId) external nonReentrant whenNotPaused {
        this._convertVeArc(msg.sender, tokenId);
    }
    
    function convertVeArcBatch(uint[] calldata tokenIds) external nonReentrant whenNotPaused {
        for (uint x = 0; x < tokenIds.length; x++) {
            try this._convertVeArc(msg.sender, tokenIds[x]) {
                
            } catch {
                emit VeArcNotConverted(tokenIds[x]);
            }
        }
    }
    
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4) {
        emit VeArcReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
}