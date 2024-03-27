// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IArc} from "./interfaces/IArc.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";

contract ArcConverter2 is Ownable2Step, Pausable, ReentrancyGuard, IERC721Receiver {
    
    IArc public fromArc;
    IVotingEscrow public fromVeArc;
    
    IArc public toArc;
    IVotingEscrow public toVeArc;
    
    uint public conversionRatio;
    uint public lockDuration;
    
    event ArcConverted(address indexed account, uint convertedAmount, uint tokenId, uint veArcAmount);
    event VeArcConverted(address indexed account, uint fromTokenId, uint convertedAmount, uint toTokenId, uint veArcAmount);
    event VeArcNotConverted(uint tokenId);
    event VeArcReceived(address indexed operator, address indexed from, uint tokenId, bytes data);
    
    constructor(address _fromArc, address _fromVeArc, address _toArc, address _toVeArc) {
        require(_fromArc != address(0) && _fromVeArc != address(0) && _toArc != address(0) && _toVeArc != address(0), 'Zero address passed in constructor');
        
        fromArc = IArc(_fromArc);
        fromVeArc = IVotingEscrow(_fromVeArc);
        
        toArc = IArc(_toArc);
        toVeArc = IVotingEscrow(_toVeArc);
        
        conversionRatio = 10;
        lockDuration = 126144000; // 4 Years
        
        _transferOwnership(0x82d3c9246890e672BA4Dfbf2038c791727BCB34A);
    }
    
    function pause() public onlyOwner
    {
        _pause();
    }
    
    function unpause() public onlyOwner
    {
        _unpause();
    }
    
    function setConversionRatio(uint newConversionRatio) public onlyOwner {
        require(newConversionRatio > conversionRatio, 'Invalid conversion ratio');
        conversionRatio = newConversionRatio;
    }
    
    function setLockDuration(uint newLockDuration) public onlyOwner {
        require(newLockDuration > 63072000, 'Invalid lock duration'); // Min of 2 Years
        lockDuration = newLockDuration;
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
        uint veArcBalance = balance / conversionRatio;
        require(veArcBalance <= toArc.balanceOf(address(this)), 'Not enough Arc v2 for conversion');
        
        fromArc.transferFrom(msg.sender, address(this), balance);
        fromArc.burn(balance);
        
        toArc.approve(address(toVeArc), veArcBalance);
        uint tokenId = toVeArc.create_lock_for(veArcBalance, lockDuration, msg.sender);
        
        emit ArcConverted(msg.sender, balance, tokenId, veArcBalance);
    }
    
    function _convertVeArc(address account, uint tokenId) public whenNotPaused {
        require(msg.sender == address(this), 'Invalid Caller');
        require(account != address(0), 'Account cannot be zero address');
        
        uint lockedAmount = fromVeArc.locked__amount(tokenId);
        uint veArcBalance = lockedAmount / conversionRatio;
        require(veArcBalance <= toArc.balanceOf(address(this)), 'Not enough Arc v2 for conversion');
        
        fromVeArc.safeTransferFrom(account, address(this), tokenId);
        fromVeArc.burn(tokenId);
        
        toArc.approve(address(toVeArc), veArcBalance);
        uint newTokenId = toVeArc.create_lock_for(veArcBalance, lockDuration, account);
        emit VeArcConverted(account, tokenId, lockedAmount, newTokenId, veArcBalance);
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