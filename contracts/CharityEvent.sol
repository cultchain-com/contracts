// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RandomizedCommittee.sol";


contract CharityEvent is ERC721Enumerable {
    using Counters for Counters.Counter;

    uint256 public constant PROPOSAL_CONFIRMATION_COMMITTEE_SIZE = 3;
    uint256 public constant MILESTONE_COMPLETION_COMMITTEE_SIZE = 3;
    RandomizedCommittee private committeeContract;

    Counters.Counter private _eventIdCounter;
    Counters.Counter private _milestoneIdCounter;

    uint256[] public allEventIds;
    enum EventMilestoneStatus { Pending, Approved, Rejected, NotStartedYet }
    struct Milestone {
        address creator;
        string name;
        string description;
        uint256 spendedAmount;
        uint256 targetAmount;
        uint256 endDate;
        uint256 ratingSum;
        uint256 ratingCount;
        uint256 committeeId;
        bool completed;
        EventMilestoneStatus status;
    }

    struct Report {
        address reporter;
        string text;
        uint256 timestamp;
    }

    struct CharityEventData {
        address creator;
        string name;
        string description;
        uint256 targetAmount;
        uint256 endDate;
        uint256 collectedAmount;
        Milestone[] milestones;
        uint256 ratingSum;
        uint256 ratingCount;
        string[] tags;
        Report[] reports;
        EventCategory category;
        EventMilestoneStatus status;
        uint256 committeeId;
    }

    enum EventCategory { Health, Education, Environment, DisasterRelief, AnimalWelfare, Others }

    mapping(uint256 => CharityEventData) private _events;
    mapping(uint256 => CharityEventData) private _eventsMilestones;


    constructor(address _committeeAddress) ERC721("CharityEvent", "CEVT") {
        committeeContract = RandomizedCommittee(_committeeAddress);
    }

    struct EventFeedback {
        address feedbackProvider;
        string feedbackText;
        uint256 timestamp;
    }

    mapping(uint256 => EventFeedback[]) private _eventFeedbacks;

    function provideEventFeedback(uint256 eventId, string memory feedbackText) external {
        EventFeedback memory eventFeedback = EventFeedback({
            feedbackProvider: msg.sender,
            feedbackText: feedbackText,
            timestamp: block.timestamp
        });

        _eventFeedbacks[eventId].push(eventFeedback);
    }

    function getEventFeedbacks(uint256 eventId) external view returns (EventFeedback[] memory) {
        return _eventFeedbacks[eventId];
    }

    function markMilestoneAsCompleted(uint256 eventId, uint256 milestoneIndex, uint256 spendedAmount) external {
        require(msg.sender == _events[eventId].creator, "Only the event creator or validators can mark milestones as completed");
        require(milestoneIndex < _events[eventId].milestones.length, "Invalid milestone index");

        _events[eventId].milestones[milestoneIndex].completed = true;
        _events[eventId].milestones[milestoneIndex].spendedAmount = spendedAmount;
        uint256 committeeId = committeeContract.formCommittee(MILESTONE_COMPLETION_COMMITTEE_SIZE);

        _events[eventId].milestones[milestoneIndex].committeeId = committeeId;
        _events[eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Pending;
    }

    function createEvent(string memory name, string memory description, uint256 targetAmount, uint256 endDate, EventCategory category) external returns (uint256) {
        // require(hasRole(PROPOSAL_CREATOR_ROLE, msg.sender), "Must have creator role to create an event");
        uint256 committeeId = committeeContract.formCommittee(PROPOSAL_CONFIRMATION_COMMITTEE_SIZE);

        _eventIdCounter.increment();
        uint256 newEventId = _eventIdCounter.current();

        _mint(msg.sender, newEventId);

        _events[newEventId].creator = msg.sender;
        _events[newEventId].name = name;
        _events[newEventId].description = description;
        _events[newEventId].targetAmount = targetAmount;
        _events[newEventId].endDate = endDate;
        _events[newEventId].collectedAmount = 0;
        _events[newEventId].ratingSum = 0;
        _events[newEventId].ratingCount = 0;
        _events[newEventId].category = category;
        _events[newEventId].status = EventMilestoneStatus.Pending;
        _events[newEventId].committeeId = committeeId;
        allEventIds.push(newEventId);

        return newEventId;
    }

    function updateEventCommitteeStatus(uint256 _eventId) external {
        RandomizedCommittee.CommitteeDecisionDetails memory committeeDetails = committeeContract.getCommitteeDecision(_events[_eventId].committeeId);
        if (committeeDetails.isCompleted == true) {
            if (committeeDetails.finalDecision == true) {
                _events[_eventId].status = EventMilestoneStatus.Approved;
            } else {
                _events[_eventId].status = EventMilestoneStatus.Rejected;
            }
        } else {
            _events[_eventId].status = EventMilestoneStatus.Pending;
        }

    }

    function updateMilestoneCommitteeStatus(uint256 _eventId, uint256 milestoneIndex) external {
        RandomizedCommittee.CommitteeDecisionDetails memory committeeDetails = committeeContract.getCommitteeDecision(_events[_eventId].milestones[milestoneIndex].committeeId);
        if (committeeDetails.isCompleted == true) {
            if (committeeDetails.finalDecision == true) {
                _events[_eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Approved;
            } else {
                _events[_eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Rejected;
            }
        } else {
            _events[_eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Pending;
        }
    }

    // Method to get details of a specific event
    function getEventDetails(uint256 eventId) external view returns (
        address creator,
        string memory name,
        string memory description,
        uint256 targetAmount,
        uint256 endDate,
        uint256 collectedAmount,
        uint256 ratingSum,
        uint256 ratingCount,
        EventCategory category,
        EventMilestoneStatus status,
        uint256 committeeId
    ) {
        CharityEventData storage eventData = _events[eventId];
        return (
            eventData.creator,
            eventData.name,
            eventData.description,
            eventData.targetAmount,
            eventData.endDate,
            eventData.collectedAmount,
            eventData.ratingSum,
            eventData.ratingCount,
            eventData.category,
            eventData.status,
            eventData.committeeId
        );
    }

    // Method to list all created events
    function listAllEvents() external view returns (uint256[] memory) {
        return allEventIds;
    }

    function isEventActive(uint256 eventId) external view returns (bool) {
        return block.timestamp <= _events[eventId].endDate;
    }

    function addMilestone(uint256 eventId, string memory milestoneName, string memory description, uint256 targetAmount, uint256 endDate) external {
        require(msg.sender == _events[eventId].creator, "Only the event creator can add milestones");
    
        Milestone memory newMilestone = Milestone({
            creator: msg.sender,
            name: milestoneName,
            description: description,
            spendedAmount: 0,
            targetAmount: targetAmount,
            endDate: endDate,
            ratingSum: 0,
            ratingCount: 0,
            committeeId: 0,
            completed: false,
            status: EventMilestoneStatus.NotStartedYet
        });
    
        _events[eventId].milestones.push(newMilestone);
    }

    function addReport(uint256 eventId, string memory reportText) external {
        Report memory newReport = Report({
            reporter: msg.sender,
            text: reportText,
            timestamp: block.timestamp
        });
        _events[eventId].reports.push(newReport);
    }

    function addTag(uint256 eventId, string memory tag) external {
        require(msg.sender == _events[eventId].creator, "Only the event creator can add tags");
        _events[eventId].tags.push(tag);
    }

    function rateEvent(uint256 eventId, uint256 rating) external {
        require(rating >= 1 && rating <= 5, "Rating should be between 1 and 5");
        _events[eventId].ratingSum += rating;
        _events[eventId].ratingCount++;
    }

    function getEventAverageRating(uint256 eventId) external view returns (uint256) {
        if (_events[eventId].ratingCount == 0) return 0;
        return _events[eventId].ratingSum / _events[eventId].ratingCount;
    }

}
