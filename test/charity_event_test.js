const Web3 = require("web3");
const assert = require("assert");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const {
  createEvent,
  addMilestone,
  markMilestoneAsCompleted,
  getEventDetails,
} = require("../scripts/charity_events/charity_event");

const {
  abi,
} = require("../artifacts/contracts/CharityEvent.sol/CharityEvent.json");

const charityEventsContract = new web3.eth.Contract(
  abi,
  "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
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
      1696174682,
      2,
      accounts[0]
    );
    assert.strictEqual(tx.status, true);
  });

  it("should add milestones to an event", async () => {
    const tx1 = await addMilestone(
      charityEventsContract,
      1,
      "Phase 1",
      "Going to build houses",
      1696174682,
      300,
      accounts[0]
    );
    const tx2 = await addMilestone(
      charityEventsContract,
      1,
      "Phase 2",
      "Going to build houses again",
      1696174682,
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
      200,
      accounts[0]
    );
    assert.strictEqual(tx.status, true);
  });

  it("should get event details", async () => {
    const tx = await createEvent(
      charityEventsContract,
      "Clean Water Project",
      "Provide clean water",
      1000,
      1696174682,
      2,
      accounts[0]
    );
    const eventDetails = await getEventDetails(charityEventsContract, 1);
    assert.strictEqual(eventDetails.name, "Clean Water Project");
    assert.strictEqual(eventDetails.description, "Provide clean water");
    assert.strictEqual(eventDetails.targetAmount.toString(), "1000");
  });
});
