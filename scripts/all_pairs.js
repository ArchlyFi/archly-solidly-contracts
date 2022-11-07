const {ethers} = require("hardhat");
const ERC20_ABI = [
    "function balanceOf(address account) external view  returns (uint256)",
    "function decimals() external view  returns (uint8)",
    "function symbol() external view  returns (string)",
    "function name() external view  returns (string)"
]
const factoryAddress = "0xDf56b2cdbFE438b8cabae1Ab74E64824C19bB242"
const chainId = 71393   // hardhat



async function main() {

    const factory = await ethers.getContractAt("BaseV1Factory", factoryAddress)

    const pairLength = await factory.allPairsLength()

    for (let i = 0; i < pairLength; i++) {
        const address = await factory.allPairs(i)
        const pair = await ethers.getContractAt("BaseV1Pair", address)

        const token0 = await getToken(await pair.token0())
        const token1 = await getToken(await pair.token1())

        const r = {
            address,
            decimals: 18,
            isStable: await pair.stable(),
            reserve0: ethers.utils.formatUnits(await pair.reserve0(), token0['decimals']),
            reserve1: ethers.utils.formatUnits(await pair.reserve1(), token1['decimals']),
            symbol: await pair.symbol(),
            totalSupply: ethers.utils.formatUnits(await pair.totalSupply(), 8),
            token0,
            token1,
        }
        console.log(r)
    }
}

async function getToken(address) {

    const token = await ethers.getContractAt(ERC20_ABI, address)
    return {
        address,
        chainId,
        decimals: await token.decimals(),
        isWhitelisted: true,
        logoURI: null,
        name: await token.name(),
        symbol: await token.symbol(),
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })