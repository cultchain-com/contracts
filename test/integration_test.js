// const Web3 = require("web3");
// const assert = require("assert");

// const {
//   createEvent,
//   addMilestone,
//   markMilestoneAsCompleted,
//   getEventDetails,
// } = require("../scripts/charity_events/charity_event");

// describe("Integration Test", () => {
//   let CharityEvents;
//   let RandomizedCommittee;
//   let charityEventsContract;
//   let randomizedCommitteeContract;
//   let owner;
//   let addr1;
//   let addr2;

//   before(async () => {
//     CharityEvents = await ethers.getContractFactory("CharityEvent");
//     RandomizedCommittee = await ethers.getContractFactory(
//       "RandomizedCommittee"
//     );

//     [owner, addr1, addr2, val1, val2, val3] = await ethers.getSigners();

//     console.log("Trying to deploy the contracts");

//     randomizedCommitteeContract = await RandomizedCommittee.deploy();
//     await randomizedCommitteeContract.deployed();

//     console.log(
//       "Randomized Contract Deployed To:",
//       randomizedCommitteeContract.address
//     );

//     charityEventsContract = await CharityEvents.deploy(
//       randomizedCommitteeContract.address
//     );
//     await charityEventsContract.deployed();

//     console.log(
//       "CharityEvent Contract Deployed To:",
//       charityEventsContract.address
//     );

//     await randomizedCommitteeContract.grantValidatorRole(
//       charityEventsContract.address
//     );
//   });

//   it("should create a charity event and add it to a committee", async function () {
//     const tx = await randomizedCommitteeContract.methods
//       .addValidator(val1)
//       .send({ from: owner });
//     await randomizedCommitteeContract.methods
//       .addValidator(val2)
//       .send({ from: owner });
//     await randomizedCommitteeContract.methods
//       .addValidator(val3)
//       .send({ from: owner });
//     // Create a charity event
//     const eventId = await createEvent(
//       charityEventsContract,
//       "Clean Water Project",
//       "Provide clean water",
//       1000,
//       1696174682,
//       2,
//       owner
//     );

//     console.log("Created EventId:", eventId);
//     const eventDetails = await getEventDetails(charityEventsContract, eventId);

//     // validators decision
//     await recordDecision(
//       randomizedCommitteeContract,
//       eventDetails.committeeId,
//       true,
//       "Its okay",
//       val1
//     );

//     await recordDecision(
//       randomizedCommitteeContract,
//       eventDetails.committeeId,
//       true,
//       "Its also okay",
//       val2
//     );

//     await recordDecision(
//       randomizedCommitteeContract,
//       eventDetails.committeeId,
//       false,
//       "Its not okay",
//       val3
//     );

//     // Validate
//     eventDetails = await getEventDetails(charityEventsContract, eventId);
//     expect(eventDetails.name).to.equal("Clean Water");

//     // const committeeDetails =
//     //   await randomizedCommitteeContract.getCommitteeDetails(eventId);
//     // expect(committeeDetails.eventAddress).to.equal(
//     //   charityEventsContract.address
//     // );
//   });
// });
