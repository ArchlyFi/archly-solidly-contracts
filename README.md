

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

### veNFT distribution recipients

| Name | Address | Qty |
| :--- | :--- | :--- |
TBD

### Testnet deployment

| Name | Address |
| :--- | :--- |
| wTLOS| [0xae85bf723a9e74d6c663dd226996ac1b8d075aa9](https://testnet.teloscan.io/address/0xae85bf723a9e74d6c663dd226996ac1b8d075aa9#code) |
| sTLOS| [0xa9991e4daa44922d00a78b6d986cdf628d46c4dd](https://testnet.teloscan.io/address/0xa9991e4daa44922d00a78b6d986cdf628d46c4dd#contract) |
| Arc | [0x1ABD3FCC5F863c86337C34775bA0A20461064ae1](https://testnet.teloscan.io/address/0x1ABD3FCC5F863c86337C34775bA0A20461064ae1#contract) |

| Name | Address |
| :--- | :--- |
| BaseV1Factory | [0xEE25D4F02065C121EcB56836d311D739F5b095cB](https://testnet.teloscan.io/address/0xEE25D4F02065C121EcB56836d311D739F5b095cB#contract) |
| BaseV1BribeFactory | [0x4DE350E95Fac3EA6792F0671911CfcbE8FEB9A6E](https://testnet.teloscan.io/address/0x4DE350E95Fac3EA6792F0671911CfcbE8FEB9A6E#contract) |
| BaseV1GaugesFactory | [0xA2A048FEA30f4e7946A77879E474fbe09Faf51c1](https://testnet.teloscan.io/address/0xA2A048FEA30f4e7946A77879E474fbe09Faf51c1#contract) |
| BaseV1Router01 | [0x01f3a58435F036EA57e70A79d5B4e44ec9b70C00](https://testnet.teloscan.io/address/0x01f3a58435F036EA57e70A79d5B4e44ec9b70C00#contract) |
| BaseV1Voter | [0xa813F33221Cd0B2F492e52534Ca5eeA0d4777F74](https://testnet.teloscan.io/address/0xa813F33221Cd0B2F492e52534Ca5eeA0d4777F74#contract) |
| veNFT | [0x0c34171C146f93F1dCAe3a129AEbD106154B096C](https://testnet.teloscan.io/address/0x0c34171C146f93F1dCAe3a129AEbD106154B096C#contract) |
| veNFT-dist | [0x52A29f8B46b9E1FE31a8C48931e858fc2407F53b](https://testnet.teloscan.io/address/0x52A29f8B46b9E1FE31a8C48931e858fc2407F53b#contract) |
| BaseV1Minter | [0x7866773289B5b3312FCfA48d8613Cc2CdB1C6598](https://testnet.teloscan.io/address/0x7866773289B5b3312FCfA48d8613Cc2CdB1C6598#contract) |

### Mainnet

| Name | Address |
| :--- | :--- |
| wTLOS| [0xd102ce6a4db07d247fcc28f366a623df0938ca9e](https://www.teloscan.io/address/0xd102ce6a4db07d247fcc28f366a623df0938ca9e#code) |
| Arc | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| BaseV1Factory | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| BaseV1BribeFactory | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| BaseV1GaugesFactory | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| BaseV1Router01 | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| BaseV1Voter | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| veNFT | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| veNFT-dist | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |
| BaseV1Minter | [0x0000000000000000000000000000000000000000](https://www.teloscan.io/address/0x0000000000000000000000000000000000000000#contract) |

## Security

- [Immunefi Bug Bounty Program](https://immunefi.com/bounty/solidly/)  
- [Bug Bounty Program](https://github.com/archlyfi/archly-solidly-contracts/blob/master/SECURITY.md)  

* [MythX: voter.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/17faf962f99a7e7e3f26f8bc.pdf)
* [MythX: ve.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/4094394a6bc512d57672533c.pdf)
* [MythX: gauges.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/4212b799deea3d9dd8f8620e.pdf)
* [MythX: core.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/79effbd69276f2d16698b72d.pdf)
* [MythX: minter.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/dea98051d23c85bcaa80dc5a.pdf)
* [PeckShield](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/e456a816-3802-4384-894c-825a4177245a.pdf)
