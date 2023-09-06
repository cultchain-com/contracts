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
const web3 = new Web3(
  new Web3.providers.HttpProvider(
    "https://lb.drpc.org/ogrpc?network=polygon-mumbai&dkey=AnfIhgajAkObjQxDb49BcekF0oq3S8YR7pVkdk2eQLM2"
  )
);

// Import ABI and contract address
const {
  abi,
} = require("../artifacts/contracts/RandomizedCommittee.sol/RandomizedCommittee.json");
const contractAddress = "0x30e9C865109777dA6B379E7744C8111ea62CBd33";

// Initialize contract
const randomizedCommitteeContract = new web3.eth.Contract(abi, contractAddress);

describe("RandomizedCommittee Contract", () => {
  let accounts;

  // Fetch accounts from web3
  before(async () => {
    accounts = [
      "8eb2e13f92e850fb487aa6ff5aa786818d440395115ba91baf34e33d6722ac24",
      "c894fb33b71ebe38a0cbd56aeebf7c6a801a0704d65859b85e6ea5a89a0d4fa2",
      "ac07f4474945693decef0d29529426ca742bc190575f114ff169c0157b8e2ebb",
      "f4b41c48318225af836ee52c036ea0b9dacf5a5e183883d118e9cb73be75bc52",
      "bc0f5af46a233e092936e051fceaa8fd4a45aeeeb7eb516a4dd295622521248d",
    ];
  });

  // Test for creating a committee
  it("should create a new committee", async () => {
    const tx = await formCommittee(randomizedCommitteeContract, 3, accounts[0]);
    assert.ok(tx);
  });

  // Test for adding members to a committee
  it("should add members to the committee", async () => {
    const tx = await addValidator(
      randomizedCommitteeContract,
      accounts[1],
      accounts[0]
    );
    assert.ok(tx);
  });
});
