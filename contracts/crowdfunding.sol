//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract CrowdFunding{

    mapping(address => uint) public contributors;
    address public admin;
    uint public numOfContributors;
    uint public minContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numOfVoters;
        mapping(address => bool) voters; 
    }

    mapping(uint => Request) public requests;
    uint public numRequests;


    enum State {INIT, STARTED, RUNNING, ENDED, CANCELED}
    State public fundingState;

    constructor(uint _goal, uint _deadline){
        admin = msg.sender;
        fundingState = State.INIT;
        goal = _goal;
        deadline = block.timestamp+ _deadline;
        minContribution = 100 wei;
        numOfContributors = 0;
    }

    modifier adminOnly(){
        require(msg.sender == admin, "message sender is not an admin");
        _;
    }

    modifier campaignRunning(){
        require(fundingState == State.RUNNING, "CrowdFunding is not running");
        require(block.timestamp <= deadline, "deadline passed");
        _;
    }

    modifier campaignEnded(){
        require(block.timestamp > deadline, "deadline passed");
        _;
    }
    modifier onlyContributor(){
        require(contributors[msg.sender] > 0, "you are not a contributor");
        _;
    }

    receive() payable external{
        contribute();
    }

    function startCampaign() public adminOnly{
        fundingState = State.RUNNING;
    }

    function contribute() public payable campaignRunning{
        require(msg.value >= minContribution, "didnt reach min contribution");
        if(contributors[msg.sender] == 0){
            numOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function requestRefund() public payable onlyContributor{
        require(fundingState == State.CANCELED || block.timestamp > deadline && raisedAmount < goal);
        
        uint value = contributors[msg.sender];
        contributors[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }

    function addRequest(string memory _description, address payable _recipient,uint _value ) public adminOnly{
        Request storage req = requests[numRequests];
        numRequests++;

        req.description = _description;
        req.recipient = _recipient;
        req.value = _value;
        req.completed = false;
        req.numOfVoters = 0;
    }

    function voteRequest(uint _requestNumber) public onlyContributor {
        Request storage req = requests[_requestNumber];
        require(req.voters[msg.sender] == false, "you already voted");
        req.voters[msg.sender] = true;
        req.numOfVoters++;
    }

}