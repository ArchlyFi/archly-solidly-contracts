// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IPair} from "./interfaces/IPair.sol";
import {Pair} from "./Pair.sol";

contract PairFactory {

    bool public isPaused;
    address public admin;
    address public pendingAdmin;
    
    uint256 public stableFee;
    uint256 public volatileFee;
    uint256 public constant MAX_FEE = 500; // 5%
    mapping(address => bool) public feeManagers;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals
    mapping(address => uint256) public feesOverrides;
    
    address internal _temp0;
    address internal _temp1;
    bool internal _temp;

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint);

    constructor() {
        isPaused = false;
        stableFee = 5; // 0.05%, Base: 10000
        volatileFee = 30; // 0.30%, Base: 10000
        admin = msg.sender;
        feeManagers[msg.sender] = true;
        feeManagers[0x0c5D52630c982aE81b78AB2954Ddc9EC2797bB9c] = true;
        feeManagers[0x726461FA6e788bd8a79986D36F1992368A3e56eA] = true;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "PairFactory: only admin");
        _;
    }
    
    modifier onlyFeeManagers() 
    {
        require(feeManagers[msg.sender], 'PairFactory: only fee manager');
        _;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    
    function setAdmin(address _admin) external onlyAdmin {
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
    }

    function setPause(bool _state) external onlyAdmin {
        isPaused = _state;
    }
    
    function manageFeeManager(address feeManager, bool _value) external onlyAdmin
    {
        feeManagers[feeManager] = _value;
    }
    
    function setFee(bool _stable, uint256 _fee) external onlyFeeManagers {
        require(_fee <= MAX_FEE, 'fee too high');
        require(_fee != 0, 'fee must be nonzero');
        if (_stable) {
            stableFee = _fee;
        } else {
            volatileFee = _fee;
        }
    }

    function setFeesOverrides(address _pair, uint256 _fee) external onlyFeeManagers {
        require(_fee <= MAX_FEE, "fee too high");
        require(_fee != 0, "fee must be nonzero");
        feesOverrides[_pair] = _fee;
    }

    function getRealFee(address _pair) public view returns(uint256) {
    	/// to get base fees, call `stableFee()` or `volatileFee()`
    	uint feeOverride = feesOverrides[_pair];
    	if(feeOverride > 0) {
    		return feeOverride;
    	}
    	else {
    		return IPair(_pair).stable() ? stableFee : volatileFee;
    	}
    }

    function getFee(bool _stable) public view returns(uint256) {
    	/// This method, when called by an actual Pair contract itself, would return the real fees.
    	/// If simply read, it will show basic fees: stableFee, or the volatileFee.
    	/// Please use the `getRealFees` method instead for your Analytics / Dapps / Usecases!
    	/// If you want to request a flashloan from any Pair, please query `getRealFee` instead.
    	address caller = msg.sender;
    	if(isPair[caller]) {
    		uint feeOverride = feesOverrides[caller];
    		if(feeOverride > 0) {
    			return feeOverride;
    		}
    		else {
                return _stable ? stableFee : volatileFee;	//non-overridden fee is base fee.
            } 
    	} else {
            return _stable ? stableFee : volatileFee;	//non-pair callers (caller) see base fee.
        }
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(Pair).creationCode);
    }

    function getInitializable() external view returns (address, address, bool) {
        return (_temp0, _temp1, _temp);
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(tokenA != tokenB, 'IA'); // BaseV1: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZA'); // BaseV1: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), 'PE'); // BaseV1: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        (_temp0, _temp1, _temp) = (token0, token1, stable);
        pair = address(new Pair{salt:salt}());
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
}
