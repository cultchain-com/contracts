const hre = require("hardhat");

async function main() {
  const RandomizedCommittee = await hre.ethers.getContractFactory(
    "RandomizedCommittee"
  );
  const randomizedCommittee = await RandomizedCommittee.deploy();

  await randomizedCommittee.deployed();

  console.log("RandomizedCommittee deployed to:", randomizedCommittee.address);

  const CharityEvent = await hre.ethers.getContractFactory("CharityEvent");
  const charityEvent = await CharityEvent.deploy(randomizedCommittee.address);

  await charityEvent.deployed();
  console.log("CharityEvent deployed to:", charityEvent.address);

  await randomizedCommittee.grantValidatorRole(charityEvent.address);
  console.log("Validator Role granted to charity contract");

  const Validator = await hre.ethers.getContractFactory("Validator");
  const validator = await Validator.deploy(randomizedCommittee.address);

  await validator.deployed();
  console.log("Validator Contract deployed at:", validator.address);

  const Fundraising = await hre.ethers.getContractFactory("Fundraising");
  const fundraising = await Fundraising.deploy(
    charityEvent.address,
    randomizedCommittee.address,
    "0x3da2581ad70D98a45ebE7D3A51D821ddDe640432"
  );

  await fundraising.deployed();
  console.log("Fundraising contract deployed at:", fundraising.address);

  await randomizedCommittee.updateValidatorCharityEventAddress(
    validator.address,
    charityEvent.address
  );
  console.log(
    "Validator and Charity Event contract address updated at Randomized Committee"
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
