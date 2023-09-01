const Web3 = require("web3");
const assert = require("assert");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545")); // Replace with your RPC endpoint
const { abi } = require("./CharityEvents.json"); // Replace with your ABI

const charityEventsContract = new web3.eth.Contract(
  abi,
  "0xYourContractAddress"
);

describe("CharityEvents Contract", () => {
  let accounts;

  before(async () => {
    accounts = await web3.eth.getAccounts();
  });

  it("should create a charity event", async () => {
    const tx = await createEvent(
      charityEventsContract,
      "Clean Water Project",
      "Provide clean water",
      1000,
      accounts[0]
    );
    assert.strictEqual(tx.status, true);
  });

  it("should add milestones to an event", async () => {
    const tx1 = await addMilestone(
      charityEventsContract,
      1,
      "Phase 1",
      300,
      accounts[0]
    );
    const tx2 = await addMilestone(
      charityEventsContract,
      1,
      "Phase 2",
      700,
      accounts[0]
    );
    assert.strictEqual(tx1.status, true);
    assert.strictEqual(tx2.status, true);
  });

  it("should mark milestones as completed", async () => {
    const tx = await markMilestoneAsCompleted(
      charityEventsContract,
      1,
      1,
      accounts[0]
    );
    assert.strictEqual(tx.status, true);
  });

  it("should get event details", async () => {
    const eventDetails = await getEventDetails(charityEventsContract, 1);
    assert.strictEqual(eventDetails.name, "Clean Water Project");
    assert.strictEqual(eventDetails.description, "Provide clean water");
    assert.strictEqual(eventDetails.targetAmount, "1000");
  });
});
