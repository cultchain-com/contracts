const Web3 = require("web3");
const { assert } = require("chai");

// Initialize web3
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545")); // Replace with your RPC endpoint

// Import ABI and contract address
const { abi } = require("./RandomizedCommittee.json"); // Replace with your ABI
const contractAddress = "0xYourContractAddress"; // Replace with your contract address

// Initialize contract
const randomizedCommitteeContract = new web3.eth.Contract(abi, contractAddress);

describe("RandomizedCommittee Contract", () => {
  let accounts;

  // Fetch accounts from web3
  before(async () => {
    accounts = await web3.eth.getAccounts();
  });

  // Test for creating a committee
  it("should create a new committee", async () => {
    const tx = await randomizedCommitteeContract.methods
      .createCommittee("Committee1")
      .send({ from: accounts[0] });
    assert.ok(tx);
  });

  // Test for adding members to a committee
  it("should add members to the committee", async () => {
    const tx = await randomizedCommitteeContract.methods
      .addMember("Committee1", "Member1")
      .send({ from: accounts[0] });
    assert.ok(tx);
  });

  // Test for selecting a random member from the committee
  it("should select a random member from the committee", async () => {
    const randomMember = await randomizedCommitteeContract.methods
      .selectRandomMember("Committee1")
      .call();
    assert.ok(randomMember);
  });

  // Test for getting committee details
  it("should get the details of a committee", async () => {
    const details = await randomizedCommitteeContract.methods
      .getCommitteeDetails("Committee1")
      .call();
    assert.ok(details);
  });
});
