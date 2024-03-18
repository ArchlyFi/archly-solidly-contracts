

![alt text](header.png)


Archly is a fork of Solidly, that allows low cost, near 0 slippage trades on uncorrelated or tightly correlated assets. The protocol incentivizes fees instead of liquidity. Liquidity providers (LPs) are given incentives in the form of `token`, the amount received is calculated as follows;

* 100% of weekly distribution weighted on votes from ve-token holders

The above is distributed to the `gauge` (see below), however LPs will earn between 40% and 100% based on their own ve-token balance.

LPs with 0 ve* balance, will earn a maximum of 40%.

## AMM

What differentiates Archly's AMM;

Archly AMMs are compatible with all the standard features as popularized by Uniswap V2, these include;

* Lazy LP management
* Fungible LP positions
* Chained swaps to route between pairs
* priceCumulativeLast that can be used as external TWAP
* Flashloan proof TWAP
* Direct LP rewards via `skim`
* xy>=k

Archly adds on the following features;

* 0 upkeep 30 minute TWAPs. This means no additional upkeep is required, you can quote directly from the pair
* Fee split. Fees do not auto accrue, this allows external protocols to be able to profit from the fee claim
* New curve: x3y+y3x, which allows efficient stable swaps
* Curve quoting: `y = (sqrt((27 a^3 b x^2 + 27 a b^3 x^2)^2 + 108 x^12) + 27 a^3 b x^2 + 27 a b^3 x^2)^(1/3)/(3 2^(1/3) x) - (2^(1/3) x^3)/(sqrt((27 a^3 b x^2 + 27 a b^3 x^2)^2 + 108 x^12) + 27 a^3 b x^2 + 27 a b^3 x^2)^(1/3)`
* Routing through both stable and volatile pairs
* Flashloan proof reserve quoting

## token

**TBD**

## ve-token

Vested Escrow (ve), this is the core voting mechanism of the system, used by `BaseV1Factory` for gauge rewards and gauge voting.

This is based off of ve(3,3) as proposed [here](https://andrecronje.medium.com/ve-3-3-44466eaa088b)

* `deposit_for` deposits on behalf of
* `emit Transfer` to allow compatibility with third party explorers
* balance is moved to `tokenId` instead of `address`
* Locks are unique as NFTs, and not on a per `address` basis

```
function balanceOfNFT(uint) external returns (uint)
```

## BaseV1Pair

Base V1 pair is the base pair, referred to as a `pool`, it holds two (2) closely correlated assets (example USDT-USDC) if a stable pool or two (2) uncorrelated assets (example TLOS-KARMA) if not a stable pool, it uses the standard UniswapV2Pair interface for UI & analytics compatibility.

```
function mint(address to) external returns (uint liquidity)
function burn(address to) external returns (uint amount0, uint amount1)
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external
```

Functions should not be referenced directly, should be interacted with via the BaseV1Router

Fees are not accrued in the base pair themselves, but are transfered to `BaseV1Fees` which has a 1:1 relationship with `BaseV1Pair`

### BaseV1Factory

Base V1 factory allows for the creation of `pools` via ```function createPair(address tokenA, address tokenB, bool stable) external returns (address pair)```

Base V1 factory uses an immutable pattern to create pairs, further reducing the gas costs involved in swaps

Anyone can create a pool permissionlessly.

### BaseV1Router

Base V1 router is a wrapper contract and the default entry point into Stable V1 pools.

```

function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity)

function removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) public ensure(deadline) returns (uint amountA, uint amountB)

function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
) external ensure(deadline) returns (uint[] memory amounts)

```

## Gauge

Gauges distribute arbitrary `token(s)` rewards to BaseV1Pair LPs based on voting weights as defined by `ve` voters.

Arbitrary rewards can be added permissionlessly via ```function notifyRewardAmount(address token, uint amount) external```

Gauges are completely overhauled to separate reward calculations from deposit and withdraw. This further protect LP while allowing for infinite token calculations.

Previous iterations would track rewardPerToken as a shift everytime either totalSupply, rewardRate, or time changed. Instead we track each individually as a checkpoint and then iterate and calculation.

## Bribe

Gauge bribes are natively supported by the protocol, Bribes inherit from Gauges and are automatically adjusted on votes.

Users that voted can claim their bribes via calling ```function getReward(address token) public```

Fees accrued by `Gauges` are distributed to `Bribes`

### BaseV1Voter

Gauge factory permissionlessly creates gauges for `pools` created by `BaseV1Factory`. Further it handles voting for 100% of the incentives to `pools`.

```
function vote(address[] calldata _poolVote, uint[] calldata _weights) external
function distribute(address token) external
```

## DEX v1 Contract Addresses

### Arbitrum One

| Name | Address |
| :--- | :--- |
| Arc | [0x9435Ffb33Ce0180F55E08490C606eC3BD07da929](https://arbiscan.io/address/0x9435Ffb33Ce0180F55E08490C606eC3BD07da929#code) |
| veArc | [0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9](https://arbiscan.io/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) |
| veArc-dist | [0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795](https://arbiscan.io/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) |
| BaseV1Factory | [0xeafBFeb64F8e3793D7d1767774efd33b203200C9](https://arbiscan.io/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) |
| BaseV1Router01 | [0x684802262D614D0Cd0C9571672F03Dd9e85D7824](https://arbiscan.io/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) |
| BaseV1Router02 | [0x6101b5e993b9d3A823f3cE1917Be265aBD19E845](https://arbiscan.io/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#code) |
| BaseV1GaugeFactory | [0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504](https://arbiscan.io/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) |
| BaseV1BribeFactory | [0xd9Fd10945d69053Eadd365B786977B6290fea088](https://arbiscan.io/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) |
| BaseV1BribeV2Factory | [0xbf9d939436f643823FfDeDE99E2602f75D0df234](https://arbiscan.io/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#code) |
| BaseV1BribeV2Factory (2.1) | [0x9cC1fc700695c21730E3a84748A50705F3f0655D](https://arbiscan.io/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#code) |
| BaseV1Voter | [0xA978acE8D8809213Cd5e6212197196cB847129E9](https://arbiscan.io/address/0xA978acE8D8809213Cd5e6212197196cB847129E9#code) |
| BaseV1Minter | [0xE9d7623f44b7726FE2013c2f8043051358731320](https://arbiscan.io/address/0xE9d7623f44b7726FE2013c2f8043051358731320#code) |

### Base

| Name | Address |
| :--- | :--- |
| Arc | [0x684802262D614D0Cd0C9571672F03Dd9e85D7824](https://basescan.org/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) |
| veArc | [0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9](https://basescan.org/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) |
| veArc-dist | [0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795](https://basescan.org/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) |
| BaseV1Factory | [0xBa06043a777652BAF540CcC785EDaFd94eE05b37](https://basescan.org/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37#code) |
| BaseV1Router02 | [0xeafBFeb64F8e3793D7d1767774efd33b203200C9](https://basescan.org/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) |
| BaseV1GaugeFactory | [0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504](https://basescan.org/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) |
| BaseV1BribeFactory | [0xd9Fd10945d69053Eadd365B786977B6290fea088](https://basescan.org/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) |
| BaseV1BribeV2Factory (2.1) | [0x12BfB58c8Fb5De8CE77b45F465eF9D2613D4B5e6](https://basescan.org/address/0x12BfB58c8Fb5De8CE77b45F465eF9D2613D4B5e6#code) |
| BaseV1Voter | [0xA978acE8D8809213Cd5e6212197196cB847129E9](https://basescan.org/address/0xA978acE8D8809213Cd5e6212197196cB847129E9#code) |
| BaseV1Minter | [0xE9d7623f44b7726FE2013c2f8043051358731320](https://basescan.org/address/0xE9d7623f44b7726FE2013c2f8043051358731320#code) |

### Arbitrum Nova, BNB Chain, Fantom, Kava, Optimism, and Polygon

| Name | Address | Arbitrum Nova| BNB Chain | Fantom | Kava | Optimism | Polygom |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Arc | 0x684802262D614D0Cd0C9571672F03Dd9e85D7824 | [contract](https://nova.arbiscan.io/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) | [contract](https://bscscan.com/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) | [contract](https://ftmscan.com/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) | [contract](https://explorer.kava.io/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824/contracts) | [contract](https://optimistic.etherscan.io/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) | [contract](https://polygonscan.com/address/0x684802262D614D0Cd0C9571672F03Dd9e85D7824#code) | 
| veArc | 0xf070654b08595f8F358Ff90170829892F3254C67 | [contract](https://nova.arbiscan.io/address/0xf070654b08595f8F358Ff90170829892F3254C67#code) | [contract](https://bscscan.com/address/0xf070654b08595f8F358Ff90170829892F3254C67#code) | [contract](https://ftmscan.com/address/0xf070654b08595f8F358Ff90170829892F3254C67#code) | [contract](https://explorer.kava.io/address/0xf070654b08595f8F358Ff90170829892F3254C67/contracts) | [contract](https://optimistic.etherscan.io/address/0xf070654b08595f8F358Ff90170829892F3254C67#code) | [contract](https://polygonscan.com/address/0xf070654b08595f8F358Ff90170829892F3254C67#code) | 
| veArc-Dist | 0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9 | [contract](https://nova.arbiscan.io/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) | [contract](https://bscscan.com/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) | [contract](https://ftmscan.com/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) | [contract](https://explorer.kava.io/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9/contracts) | [contract](https://optimistic.etherscan.io/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) | [contract](https://polygonscan.com/address/0x4c01dF6B9be381BA2a687D0ED5c40039dEEaf0a9#code) | 
| BaseV1Factory | 0xBa06043a777652BAF540CcC785EDaFd94eE05b37 | [contract](https://nova.arbiscan.io/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37#code) | [contract](https://bscscan.com/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37#code) | [contract](https://ftmscan.com/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37#code) | [contract](https://explorer.kava.io/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37/contracts) | [contract](https://optimistic.etherscan.io/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37#code) | [contract](https://polygonscan.com/address/0xBa06043a777652BAF540CcC785EDaFd94eE05b37#code) | 
| BaseV1Router01 | 0xeafBFeb64F8e3793D7d1767774efd33b203200C9 | [contract](https://nova.arbiscan.io/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) | [contract](https://bscscan.com/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) | [contract](https://ftmscan.com/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) | [contract](https://explorer.kava.io/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9/contracts) | [contract](https://optimistic.etherscan.io/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) | [contract](https://polygonscan.com/address/0xeafBFeb64F8e3793D7d1767774efd33b203200C9#code) | 
| BaseV1Router02 | 0x6101b5e993b9d3A823f3cE1917Be265aBD19E845 | [contract](https://nova.arbiscan.io/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#code) | [contract](https://bscscan.com/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#code) | [contract](https://ftmscan.com/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#code) | [contract](https://explorer.kava.io/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845/contracts) | [contract](https://optimistic.etherscan.io/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#code) | [contract](https://polygonscan.com/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#code) | 
| BaseV1GaugeFactory | 0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795 | [contract](https://nova.arbiscan.io/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) | [contract](https://bscscan.com/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) | [contract](https://ftmscan.com/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) | [contract](https://explorer.kava.io/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795/contracts) | [contract](https://optimistic.etherscan.io/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) | [contract](https://polygonscan.com/address/0x5A63409C88dDD327A56eEf3a3492Bb0Ce74ba795#code) | 
| BaseV1BribeFactory | 0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504 | [contract](https://nova.arbiscan.io/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) | [contract](https://bscscan.com/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) | [contract](https://ftmscan.com/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) | [contract](https://explorer.kava.io/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504/contracts) | [contract](https://optimistic.etherscan.io/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) | [contract](https://polygonscan.com/address/0xbc5AAF4970E50B2504C2441367B87B6F3D9Ac504#code) | 
| BaseV1BribeV2Factory | 0xbf9d939436f643823FfDeDE99E2602f75D0df234 | [contract](https://nova.arbiscan.io/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#code) | [contract](https://bscscan.com/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#code) | [contract](https://ftmscan.com/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#code) | [contract](https://explorer.kava.io/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234/contracts) | [contract](https://optimistic.etherscan.io/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#code) | [contract](https://polygonscan.com/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#code) | 
| BaseV1BribeV2Factory (2.1) | 0x9cC1fc700695c21730E3a84748A50705F3f0655D | [contract](https://nova.arbiscan.io/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#code) | [contract](https://bscscan.com/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#code) | [contract](https://ftmscan.com/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#code) | [contract](https://explorer.kava.io/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D/contracts) | [contract](https://optimistic.etherscan.io/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#code) | [contract](https://polygonscan.com/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#code) | 
| BaseV1Voter | 0xd9Fd10945d69053Eadd365B786977B6290fea088 | [contract](https://nova.arbiscan.io/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) | [contract](https://bscscan.com/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) | [contract](https://ftmscan.com/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) | [contract](https://explorer.kava.io/address/0xd9Fd10945d69053Eadd365B786977B6290fea088/contracts) | [contract](https://optimistic.etherscan.io/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) | [contract](https://polygonscan.com/address/0xd9Fd10945d69053Eadd365B786977B6290fea088#code) | 
| BaseV1Minter | 0xd865043A22604Caf267422283B8601A9d546301f | [contract](https://nova.arbiscan.io/address/0xd865043A22604Caf267422283B8601A9d546301f#code) | [contract](https://bscscan.com/address/0xd865043A22604Caf267422283B8601A9d546301f#code) | [contract](https://ftmscan.com/address/0xd865043A22604Caf267422283B8601A9d546301f#code) | [contract](https://explorer.kava.io/address/0xd865043A22604Caf267422283B8601A9d546301f/contracts) | [contract](https://optimistic.etherscan.io/address/0xd865043A22604Caf267422283B8601A9d546301f#code) | [contract](https://polygonscan.com/address/0xd865043A22604Caf267422283B8601A9d546301f#code) | 

### Telos Mainnet

| Name | Address |
| :--- | :--- |
| wTLOS| [0xd102ce6a4db07d247fcc28f366a623df0938ca9e](https://www.teloscan.io/address/0xd102ce6a4db07d247fcc28f366a623df0938ca9e#code) |
| Arc | [0xa84df7aFbcbCC1106834a5feD9453bd1219B1fb5](https://www.teloscan.io/address/0xa84df7aFbcbCC1106834a5feD9453bd1219B1fb5#contract) |
| veArc | [0x5680b3059b860d07A33B7A43d03D2E4dEdb226BB](https://www.teloscan.io/address/0x5680b3059b860d07A33B7A43d03D2E4dEdb226BB#contract) |
| veArc-dist | [0x9763cD8DA9e1ED99490893A8bcd64e5e87E7cd3C](https://www.teloscan.io/address/0x9763cD8DA9e1ED99490893A8bcd64e5e87E7cd3C#contract) |
| BaseV1Factory | [0x39fdd4Fec9b41e9AcD339a7cf75250108D32906c](https://www.teloscan.io/address/0x39fdd4Fec9b41e9AcD339a7cf75250108D32906c#contract) |
| BaseV1Router01 | [0x7BF5247c2d8cC4Ad7b588898B1ED3594815Ca3f9](https://www.teloscan.io/address/0x7BF5247c2d8cC4Ad7b588898B1ED3594815Ca3f9#contract) |
| BaseV1Router02 | [0x6101b5e993b9d3A823f3cE1917Be265aBD19E845](https://www.teloscan.io/address/0x6101b5e993b9d3A823f3cE1917Be265aBD19E845#contract) |
| BaseV1GaugeFactory | [0x3D5eA100C38c0Af9f5d94105EA4E160AeE6DC668](https://www.teloscan.io/address/0x3D5eA100C38c0Af9f5d94105EA4E160AeE6DC668#contract) |
| BaseV1BribeFactory | [0x11ca072a392D92ca63976CD9c1dc38de1FE578ee](https://www.teloscan.io/address/0x11ca072a392D92ca63976CD9c1dc38de1FE578ee#contract) |
| BaseVBribeV2Factory | [0xbf9d939436f643823FfDeDE99E2602f75D0df234](https://www.teloscan.io/address/0xbf9d939436f643823FfDeDE99E2602f75D0df234#contract) |
| BaseVBribeV2Factory (2.1) | [0x9cC1fc700695c21730E3a84748A50705F3f0655D](https://www.teloscan.io/address/0x9cC1fc700695c21730E3a84748A50705F3f0655D#contract) |
| BaseV1Voter | [0xd9742c670eEE8001d965964E05793c42c588B657](https://www.teloscan.io/address/0xd9742c670eEE8001d965964E05793c42c588B657#contract) |
| BaseV1Minter | [0xdB6db572DA4be59656f87Ee5711D8334e1f9b0E9](https://www.teloscan.io/address/0xdB6db572DA4be59656f87Ee5711D8334e1f9b0E9#contract) |

## DEX v2 Contract Addresses

### (All Chains except zkSync Era)

| Name | Address |
| :--- | :--- |
| Arc | 0xe8876189A80B2079D8C0a7867e46c50361D972c1 |
| VeArc | 0x6ACa098fa93DAD7A872F6dcb989F8b4A3aFC3342 |
| VeArcDistributor | 0x0361a173dC338c32E57079b2c51cEf36f8A982f1 |
| PairFactory | 0x12508dd9108Abab2c5fD8fC6E4984E46a3CF7824 |
| Router | 0xE8E2b714C57937E0b29c6ABEAF00B52388cAb598 |
| GaugeFactory | 0xb33F66f27d8D8282AC1f55F98cd83503e90128e9 |
| BribeFactory | 0xc8c5172879f0b7E88cc03ca20835dbE9e283386e |
| Voter | 0x0B1481fE6Fd74a6449064163604d712DFf9bc6DD |
| Minter | 0x14EAfc4ceB334d4f913204647708aBAD1ceF0854 |

### (zkSync Era)

| Name | Address |
| :--- | :--- |
| Arc | 0xfB4c64c144c2bD0E7F2A06da7d6aAc32d8cb2514 |
| VeArc | 0x483BdBdbf60d9650845c8097E002c2241D92ab45 |
| VeArcDistributor | 0x51FacD6bFb361920A949e942CAec12dde9AaCd5a |
| PairFactory | 0x30A0DD3D0D9E99BD0E67b323FB706788766dCff2 |
| Router | 0x2980aa5bD6980B6506682c56b3D3d34D13D98E6D |
| GaugeFactory | 0x15E21A438853AFa27EBB53710bfe0f3Cfcb6Abd6 |
| BribeFactory | 0x8583c59b3acA38A72D84FB75fd05D520B57163f4 |
| Voter | 0x5cD247e2591E33a6C8F636F169089B43988d8a18 |
| Minter | 0xc37b9A8deB9B33507f44B04CF94B04170900cC57 |

## Security

* [MythX: voter.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/17faf962f99a7e7e3f26f8bc.pdf)
* [MythX: ve.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/4094394a6bc512d57672533c.pdf)
* [MythX: gauges.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/4212b799deea3d9dd8f8620e.pdf)
* [MythX: core.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/79effbd69276f2d16698b72d.pdf)
* [MythX: minter.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/dea98051d23c85bcaa80dc5a.pdf)
* [PeckShield](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/e456a816-3802-4384-894c-825a4177245a.pdf)
