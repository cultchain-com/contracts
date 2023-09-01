const Web3 = require("web3");
const { assert } = require("chai");
const {
  formCommittee,
  getMyDecisions,
  isCommitteeMember,
  recordDecision,
  getValidatorCount,
  getCommitteeDecision,
  getValidatorProfile,
  removeValidator,
  addValidator,
} = require("../scripts/randomized_committee/randomized_committee");

// Initialize web3
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

// Import ABI and contract address
const {
  abi,
} = require("../artifacts/contracts/RandomizedCommittee.sol/RandomizedCommittee.json");
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

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
    const tx = await formCommittee(randomizedCommitteeContract, 3, accounts[0]);
    assert.ok(tx);
  });

  // Test for adding members to a committee
  it("should add members to the committee", async () => {
    const tx = await addValidator(randomizedCommitteeContract, accounts[1], accounts[0])
    assert.ok(tx);
  });

});
