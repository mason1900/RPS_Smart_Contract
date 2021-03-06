pragma solidity ^0.4.22;
/**
    @title Simple Rock Paper scissors
    @notice This contract is not safe for user because the player hand is not encrypted. For test purpose only. register() first for each player then play().
    @dev Considering encrypted hands in future versions.
*/
contract rps_simple
{
    struct Player
    {
        bool joined;
        address account;
        bool voted;
        string choice;
    }
    
    Player public player1;
    Player public player2;
    uint public stage;
    uint public position;
    mapping(string => mapping(string => uint)) payoffMatrix;
    
    event LogWinner(address player, uint playerID, string choice);
    event LogInfo(address player, string message, uint playerID, bool voted, string choice);
    
    constructor() public
    {
        //player1.voted = true;
        //player2.voted =true;
        
        payoffMatrix["rock"]["rock"] = 0;
        payoffMatrix["rock"]["paper"] = 2;
        payoffMatrix["rock"]["scissors"] = 1;
        payoffMatrix["paper"]["rock"] = 1;
        payoffMatrix["paper"]["paper"] = 0;
        payoffMatrix["paper"]["scissors"] = 2;
        payoffMatrix["scissors"]["rock"] = 2;
        payoffMatrix["scissors"]["paper"] = 1;
        payoffMatrix["scissors"]["scissors"] = 0;
    }
    
    
/*
    <-- Modifiers -->
*/
    modifier notRegistered() 
    {
        if (player1.account == msg.sender || player2.account == msg.sender)
        {
            revert("This account has already been registered in the game.");
        }
        else
            _;
    }
    
    modifier checkDeposit()
    {
        // Note: In Ethereum, the amount is sent to contract address rather than
        // the contract owner's address.
        require (msg.value == 5 ether, "Not exactly 5 ether. Please make sure unit is correct");
        _;
    }

    modifier validChoice(string _choice)
    {
        require ((keccak256(_choice) == keccak256("rock")) 
        || (keccak256(_choice) == keccak256("paper")) 
        || (keccak256(_choice) == keccak256("scissors")), "Invalid input.");
        _;       
    }


/*
    <-- Internal functions -->
*/

    // 0: no one voted. 1: one of them voted. 2: all voted.
    function updateStage() private {stage = (player1.voted ? 1 : 0) + (player2.voted ? 1 : 0);}
    // 0: no one joined. 1: one player joined. 2: all joined.
    function updatePosition() private {position = (player1.joined ? 1 : 0) + (player2.joined ? 1 : 0);}
    
    function cleanUp() private
    {
        player1.joined = false;
        player1.account = 0;
        player1.voted = false;
        player1.choice = "";
        
        player2.joined = false;
        player2.account = 0;
        player2.voted = false;
        player2.choice = "";
        
        stage = 0;
        position =0;
    }
    
    
/*
    <-- Main functions -->
*/    
    
    function joinGame()  public payable
        notRegistered()
        checkDeposit()
    {
        if (position == 0)
        {
            player1.joined = true;
            player1.account = msg.sender;
            updatePosition();
            emit LogInfo(player1.account, "joined as player 1", 1, player1.voted, player1.choice);
        }
        else if (position == 1)
        {
            player2.joined = true;
            player2.account = msg.sender;
            updatePosition();
            emit LogInfo(player2.account, "joined as player 2", 2, player2.voted, player2.choice);
        }
        else
        {
             revert("The game is full.");
        }
    }
    
    function play(string _choice) public
        validChoice(_choice)
    {
        if (msg.sender == player1.account)
        {
            player1.choice = _choice;
            player1.voted = true;
            updateStage();
            emit LogInfo(player1.account, _choice, 1, player1.voted, player1.choice);
        }
        else if (msg.sender == player2.account)
        {
            player2.choice = _choice;
            player2.voted = true;
            updateStage();
            emit LogInfo(player2.account, _choice, 2, player2.voted, player2.choice);
        }
        else
        {
            revert("Not registered yet. Join game first.");
        }
    }
    
    function checkOut() public
    {
        // Avoid an exploit.
        // See https://solidity.readthedocs.io/en/v0.4.24/solidity-by-example.html
        // the comments of withdraw().
        bool tranferInProgress = false;
        require(!tranferInProgress);
        
        // require all joined and voted
        require(position == 2 && stage == 2);
        
        uint winner = payoffMatrix[player1.choice][player2.choice];
        if (winner == 1)
        {
            tranferInProgress = true;
            player1.account.transfer(this.balance);
            emit LogWinner(player1.account, 1, player1.choice);
        }
        else if (winner == 2)
        {
            tranferInProgress = true;
            player2.account.transfer(this.balance);
            emit LogWinner(player2.account, 2, player2.choice);
        }
        else
        {
            // Note: this is still unsafe because dealing with mutiple accounts.
            // May improve in the future.
            tranferInProgress = true;
            player1.account.transfer(this.balance/2);
            player2.account.transfer(this.balance);
            emit LogWinner(0, 0, "");
        }
        cleanUp();
    }
    
/*
    <-- Helper functions -->
*/
    
    function getContractBalance() view public returns (uint amount)
    {
        // Note: In Ethereum, the amount is sent to contract address rather than
        // the contract owner's address.
        // The following code is equivalent to address(contract).balance
        return this.balance;
    }
    
    function isPlayer1() public view returns (bool) 
    {
        return msg.sender == player1.account;
    }
    
    function isPlayer2() public view returns (bool)
    {
        return msg.sender == player2.account;
    }
    
}
