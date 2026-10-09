// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollingSystem {
    struct Poll {
        string title;
        string[] options;
        uint256 endTime;
        uint256[] voteCounts;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Poll) private polls;
    uint256 public pollCount;

    event PollCreated(uint256 pollId, string title);
    event VoteCast(
        uint256 pollId,
        address voter,
        uint256 optionIndex
    );

    function createPoll(
        string calldata _title,
        string[] calldata _options,
        uint256 _durationSeconds
    ) external returns (uint256) {
        require(bytes(_title).length > 0, "Title required");
        require(_options.length >= 2, "Need at least 2 options");
        require(
            _durationSeconds > 0,
            "Duration must be positive"
        );

        uint256 id = pollCount++;
        Poll storage p = polls[id];

        p.title = _title;
        p.endTime = block.timestamp + _durationSeconds;

        for (uint256 i = 0; i < _options.length; i++) {
            p.options.push(_options[i]);
            p.voteCounts.push(0);
        }

        emit PollCreated(id, _title);
        return id;
    }

    function vote(
        uint256 _pollId,
        uint256 _optionIndex
    ) external {
        require(_pollId < pollCount, "Poll does not exist");

        Poll storage p = polls[_pollId];

        require(block.timestamp < p.endTime, "Poll has ended");
        require(!p.hasVoted[msg.sender], "Already voted");
        require(_optionIndex < p.options.length, "Invalid option");

        p.hasVoted[msg.sender] = true;
        p.voteCounts[_optionIndex]++;

        emit VoteCast(_pollId, msg.sender, _optionIndex);
    }

    function getPoll(uint256 _pollId)
        external
        view
        returns (
            string memory title,
            string[] memory options,
            uint256 endTime,
            uint256[] memory voteCounts
        )
    {
        require(_pollId < pollCount, "Poll does not exist");

        Poll storage p = polls[_pollId];

        return (
            p.title,
            p.options,
            p.endTime,
            p.voteCounts
        );
    }

    function getWinner(uint256 _pollId)
        external
        view
        returns (
            string memory winner,
            uint256 winningVotes
        )
    {
        require(_pollId < pollCount, "Poll does not exist");

        Poll storage p = polls[_pollId];
        require(
            block.timestamp >= p.endTime,
            "Poll is still active"
        );

        uint256 maxVotes = 0;
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < p.voteCounts.length; i++) {
            if (p.voteCounts[i] > maxVotes) {
                maxVotes = p.voteCounts[i];
                winnerIndex = i;
            }
        }

        return (p.options[winnerIndex], maxVotes);
    }
}
