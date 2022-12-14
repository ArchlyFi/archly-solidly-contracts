

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

### Testnet deployment

| Name | Address |
| :--- | :--- |
| wTLOS| [0xae85bf723a9e74d6c663dd226996ac1b8d075aa9](https://testnet.teloscan.io/address/0xae85bf723a9e74d6c663dd226996ac1b8d075aa9#code) |
| Arc | [0x6a921C4b3f4Dfb4bD278EBA5978B0381b74ea8fa](https://testnet.teloscan.io/address/0x6a921C4b3f4Dfb4bD278EBA5978B0381b74ea8fa#contract) |
| veArc | [0x3EBfCEF3F3C0268Fa9AfB14CD461E2CC11ce0640](https://testnet.teloscan.io/address/0x3EBfCEF3F3C0268Fa9AfB14CD461E2CC11ce0640#contract) |
| veArc-dist | [0x4b71F90c5d1968c21D3dc70A59268908A20A24Ef](https://testnet.teloscan.io/address/0x4b71F90c5d1968c21D3dc70A59268908A20A24Ef#contract) |
| BaseV1Factory | [0xCEE3e7189913335D83c41aDfC3089B2B17a6a740](https://testnet.teloscan.io/address/0xCEE3e7189913335D83c41aDfC3089B2B17a6a740#contract) |
| BaseV1Router01 | [0x45A27E9Dc65143Eb0aa2249D4a1B1c5464373e29](https://testnet.teloscan.io/address/0x45A27E9Dc65143Eb0aa2249D4a1B1c5464373e29#contract) |
| BaseV1GaugeFactory | [0x0eDc4d37F3A8B30065Ceede737C60e315A95f56e](https://testnet.teloscan.io/address/0x0eDc4d37F3A8B30065Ceede737C60e315A95f56e#contract) |
| BaseV1BribeFactory | [0x538a55F9d2e1D128B378A6Ff822F073cb86111f1](https://testnet.teloscan.io/address/0x538a55F9d2e1D128B378A6Ff822F073cb86111f1#contract) |
| BaseV1Voter | [0xf6339700bb26638923dbDF7527Fe125cEae3AE70](https://testnet.teloscan.io/address/0xf6339700bb26638923dbDF7527Fe125cEae3AE70#contract) |
| BaseV1Minter | [0xc310e3d746DE609a06dB2a51eAAD58Ecd00dc84c](https://testnet.teloscan.io/address/0xc310e3d746DE609a06dB2a51eAAD58Ecd00dc84c#contract) |

### Mainnet

| Name | Address |
| :--- | :--- |
| wTLOS| [0xd102ce6a4db07d247fcc28f366a623df0938ca9e](https://www.teloscan.io/address/0xd102ce6a4db07d247fcc28f366a623df0938ca9e#code) |
| Arc | [0xa84df7aFbcbCC1106834a5feD9453bd1219B1fb5](https://www.teloscan.io/address/0xa84df7aFbcbCC1106834a5feD9453bd1219B1fb5#contract) |
| veArc | [0x5680b3059b860d07A33B7A43d03D2E4dEdb226BB](https://www.teloscan.io/address/0x5680b3059b860d07A33B7A43d03D2E4dEdb226BB#contract) |
| veArc-dist | [0x9763cD8DA9e1ED99490893A8bcd64e5e87E7cd3C](https://www.teloscan.io/address/0x9763cD8DA9e1ED99490893A8bcd64e5e87E7cd3C#contract) |
| BaseV1Factory | [0x39fdd4Fec9b41e9AcD339a7cf75250108D32906c](https://www.teloscan.io/address/0x39fdd4Fec9b41e9AcD339a7cf75250108D32906c#contract) |
| BaseV1Router01 | [0x7BF5247c2d8cC4Ad7b588898B1ED3594815Ca3f9](https://www.teloscan.io/address/0x7BF5247c2d8cC4Ad7b588898B1ED3594815Ca3f9#contract) |
| BaseV1GaugeFactory | [0x3D5eA100C38c0Af9f5d94105EA4E160AeE6DC668](https://www.teloscan.io/address/0x3D5eA100C38c0Af9f5d94105EA4E160AeE6DC668#contract) |
| BaseV1BribeFactory | [0x11ca072a392D92ca63976CD9c1dc38de1FE578ee](https://www.teloscan.io/address/0x11ca072a392D92ca63976CD9c1dc38de1FE578ee#contract) |
| BaseV1Voter | [0xd9742c670eEE8001d965964E05793c42c588B657](https://www.teloscan.io/address/0xd9742c670eEE8001d965964E05793c42c588B657#contract) |
| BaseV1Minter | [0xdB6db572DA4be59656f87Ee5711D8334e1f9b0E9](https://www.teloscan.io/address/0xdB6db572DA4be59656f87Ee5711D8334e1f9b0E9#contract) |

## Security

* [MythX: voter.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/17faf962f99a7e7e3f26f8bc.pdf)
* [MythX: ve.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/4094394a6bc512d57672533c.pdf)
* [MythX: gauges.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/4212b799deea3d9dd8f8620e.pdf)
* [MythX: core.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/79effbd69276f2d16698b72d.pdf)
* [MythX: minter.sol](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/dea98051d23c85bcaa80dc5a.pdf)
* [PeckShield](https://github.com/archlyfi/archly-solidly-contracts/blob/master/audits/e456a816-3802-4384-894c-825a4177245a.pdf)
