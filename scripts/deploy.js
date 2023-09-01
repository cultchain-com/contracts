const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RandomizedCommittee = await hre.ethers.getContractFactory(
    "RandomizedCommittee"
  );
  const randomizedCommittee =
    await RandomizedCommittee.deploy(/* constructor arguments here */);

  await randomizedCommittee.deployed();

  console.log("RandomizedCommittee deployed to:", randomizedCommittee.address);

  const CharityEvent = await hre.ethers.getContractFactory("CharityEvent");
  const charityEvent = await CharityEvent.deploy(randomizedCommittee.address);

  await charityEvent.deployed();

  console.log("CharityEvent deployed to:", charityEvent.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
