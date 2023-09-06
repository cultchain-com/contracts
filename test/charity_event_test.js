const Web3 = require("web3");
const assert = require("assert");
const web3 = new Web3(
  new Web3.providers.HttpProvider("https://rpc-mumbai.maticvigil.com/")
);

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
  "0x3E2E26Cf73D7aDFaDCa14783e63840E338D04699"
);

describe("CharityEvents Contract", () => {
  owner = web3.eth.accounts.privateKeyToAccount(
    "8eb2e13f92e850fb487aa6ff5aa786818d440395115ba91baf34e33d6722ac24"
  );
  val1 = web3.eth.accounts.privateKeyToAccount(
    "c894fb33b71ebe38a0cbd56aeebf7c6a801a0704d65859b85e6ea5a89a0d4fa2"
  );
  val2 = web3.eth.accounts.privateKeyToAccount(
    "ac07f4474945693decef0d29529426ca742bc190575f114ff169c0157b8e2ebb"
  );
  val3 = web3.eth.accounts.privateKeyToAccount(
    "f4b41c48318225af836ee52c036ea0b9dacf5a5e183883d118e9cb73be75bc52"
  );

  val4 = web3.eth.accounts.privateKeyToAccount(
    "bc0f5af46a233e092936e051fceaa8fd4a45aeeeb7eb516a4dd295622521248d"
  );
  let from = owner.address;
  console.log("Owner Account:", owner);
  before(async () => {});

  it("should create a charity event", async () => {
    const tx = await createEvent(
      charityEventsContract,
      "Clean Water Project",
      "Provide clean water",
      1000,
      1696174682,
      2,
      from
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
      from
    );
    const tx2 = await addMilestone(
      charityEventsContract,
      1,
      "Phase 2",
      "Going to build houses again",
      1696174682,
      700,
      from
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
      from
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
      from
    );
    const eventDetails = await getEventDetails(charityEventsContract, 1);
    assert.strictEqual(eventDetails.name, "Clean Water Project");
    assert.strictEqual(eventDetails.description, "Provide clean water");
    assert.strictEqual(eventDetails.targetAmount.toString(), "1000");
  });
});
