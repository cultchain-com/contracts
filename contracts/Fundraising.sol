// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./CharityEvent.sol";
import "./RandomizedCommittee.sol";

contract Fundraising {
    using Counters for Counters.Counter;

    CharityEvent private charityEventContract;
    RandomizedCommittee private randomizedCommitteeContract;

    address payable public platformAddress;

    struct Donor {
        address donorAddress;
        uint256 totalDonated;
    }

     struct ValidatorDetails {
        address validator;
        uint256 totalEarnings;
        uint256 numberOfEvents;
    }

    struct Donation {
        address donor;
        uint256 amount;
        uint256 eventId;
        uint256 timestamp;
        string message;
    }

    struct WithdrawRequestHistory {
        uint256 eventId;
        uint256 timestamp;
        uint256 requestedAmount;
        string description;
        string committeeAccept;
        address[] validators;
        bool isConfirmedByCommittee;
    }

    mapping(address => uint256[]) private _validatorsEarnings;
    mapping(uint256 => uint256) private _eventBalance;
    mapping(uint256 => Donation[]) private _eventDonations;
    mapping(address => Donation[]) private _donors;
    mapping(uint256 => WithdrawRequestHistory[]) private _eventwithdrawHistory;

    event DonatedToEvent(uint256 eventId, address donor, uint256 amount, string message);
    event WhitdrawRequested(uint256 eventId, uint256 amount);
    event FundReleasedToCreator(uint256 eventId, uint256 creatorShare, address creator);
    event FundReleasedToValidators(uint256 eventId, uint256 validatorShare, address validator);
    event FundReleasedToPlatform(uint256 eventId, uint256 platformShare, address platfrom);


    constructor(address _charityEventAddress, address _randomizedCommitteeContract, address payable _platformAddress) {
        charityEventContract = CharityEvent(_charityEventAddress);
        randomizedCommitteeContract = RandomizedCommittee(_randomizedCommitteeContract);
        platformAddress = _platformAddress;
    }


    function donateToEvent(uint256 eventId, string memory message) external payable {
        require(charityEventContract.isEventApproved(eventId), "The event is not confirmed by the committee or Fundaraising is over.");
        require(msg.value > 0, "Donation amount must be greater than 0");

        Donation memory newDonation = Donation({
            donor: msg.sender,
            amount: msg.value,
            eventId: eventId,
            timestamp: block.timestamp,
            message: message
        });
        _eventBalance[eventId] += msg.value;
        charityEventContract.updateCollectedAmount(eventId, msg.value);
        _eventDonations[eventId].push(newDonation);
        _donors[msg.sender].push(newDonation);
        emit DonatedToEvent(eventId, msg.sender, msg.value, message);
    }

    function getValidators(uint256 committeeId) public view returns(address[] memory){
        RandomizedCommittee.CommitteeDecisionDetails memory committee = randomizedCommitteeContract.getCommitteeDecision(committeeId);
        return committee.validatorAddresses;
    }

    function requestWithdraw(uint256 eventId, uint256 _amount) external {
        require(msg.sender == charityEventContract.retrieveEventCreator(eventId), "You are not the creator of the event.");
        require(charityEventContract.isEventFundraisingOver(eventId), "Fundraising is not over yet.");
        uint256 milestonesIndex;
        uint256 amount;
        (milestonesIndex, amount) = charityEventContract.possibleMilestoneAmount(eventId);
        require(_amount == amount, "Your requested amount should be the same as milestone amount");
        require(_amount <= _eventBalance[eventId], "Your requested amount is higher than the event balancce");
        emit WhitdrawRequested(eventId, amount);

        // Calculate distribution amounts
        uint256 platformAmount = (_amount * 5) / 100; // 5% for the platform
        uint256 validatorsTotalAmount = (_amount * 3) / 100; // 3% for validators
        uint256 creatorAmount = _amount - platformAmount - validatorsTotalAmount; // 92% for the event creator

        address[] memory validators;
        if (milestonesIndex == 0) {
            validators = getValidators(eventId); // This must be committeeId not the eventId
        } else {
            validators = getValidators(milestonesIndex - 1); // Must be the CommitteeId not the milestoneindex;
        }

        uint256 amountPerValidator = validatorsTotalAmount / validators.length;
        for (uint256 i = 0; i < validators.length; i++) {
            payable(validators[i]).transfer(amountPerValidator);
            _validatorsEarnings[validators[i]].push(amountPerValidator);
            emit FundReleasedToValidators(eventId, amountPerValidator, validators[i]);
        }

        platformAddress.transfer(platformAmount);
        emit FundReleasedToPlatform(eventId, platformAmount, platformAddress);
        payable(msg.sender).transfer(creatorAmount);
        emit FundReleasedToCreator(eventId, creatorAmount, msg.sender);

        WithdrawRequestHistory memory newWithdraw;
        newWithdraw.eventId = eventId;
        newWithdraw.timestamp = block.timestamp;
        newWithdraw.requestedAmount = _amount;
        newWithdraw.committeeAccept = "No comment";
        newWithdraw.validators = validators;
        newWithdraw.isConfirmedByCommittee = true;
    }

    // function refundToDonors(eventId) external {}

    function getEventDonations(uint256 eventId) external view returns (Donation[] memory) {
        return _eventDonations[eventId];
    }

    function getDonorDonations(address _address) external view returns (Donation[] memory){
        return _donors[_address];
    }

}