pragma solidity ^0.5.0;

contract Package {
  string public name;
  address public manager;

  STATUSES public status;

  enum STATUSES {
    CREATED,
    SENT,
    RECEIVED
  }

  event Action(
    string name,
    address account,
    address manager,
    uint256 timestamp
  );

  constructor(string memory _name, uint256 _price) public {
    // Set name
    name = _name;

    // Make deployer manager
    manager = msg.sender;

    // Update status to "CREATED"
    status = STATUSES.CREATED;

    // Log history
    emit Action("CREATE", msg.sender, msg.sender, now);
  }

  function send(address _to) public {
    // Must be manager to send
    require(msg.sender == manager);

    // Cannot send to self
    require(_to != manager);

    // Can't be in "SENT" status
    // Must be "CREATED" or "RECEIVED"
    require(status != STATUSES.SENT);

    // Update status to "SENT"
    status = STATUSES.SENT;

    // Make _to new manager
    manager = _to;

    // Log history
    emit Action("SEND", msg.sender, _to, now);
  }

  function receive() public {
    // Must be manager to receive
    require(msg.sender == manager);

    // Must be in "SENT" status
    // Cannot be "CREATED" or "RECEIVED"
    require(status == STATUSES.SENT);

    // Update status to "RECEIVED"
    status = STATUSES.RECEIVED;

    // Log history
    emit Action("RECEIVE", msg.sender, msg.sender, now);
  }
}
