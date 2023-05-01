const { network } = require('hardhat');
const hre = require('hardhat');

const provider = hre.ethers.provider;
async function main() {
  const gasPrice = await provider.getGasPrice();

  const ERC20 = await hre.ethers.getContractFactory('TrikonToken');
  const erc20 = await ERC20.deploy();
  await erc20.deployed();

  console.log(`TestERC20 deployed at ${erc20.address} in network: ${network}.`);

  const Marketplace = await hre.ethers.getContractFactory('BuyNFT');

  const marketplace = await Marketplace.deploy(erc20.address);
  await marketplace.deployed();

  console.log(
    `Marketplace deployed at ${marketplace.address} in network: ${network}.`
  );

  //* ----------------- Auto Verification Function -------------

  await sleep(1000);

  await hre.run('verify:verify', {
    address: creator.address,
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
