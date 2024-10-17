// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Token.sol";
import "hardhat/console.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

contract TokenFactory {

    struct memeToken {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        uint fundingRaised;
        address tokenAddress;
        address creatorAddress;
    }

    address[] public memeTokenAddresses;

    mapping(address => memeToken) public addressToMemeTokenMapping;

    uint MEMETOKEN_CREATION_PLATFORM_FEE = 0.0001 ether;
    uint MEMECOIN_FUNDING_DEADLINE_DURATION = 10 days;
    uint MEMECOIN_FUNDING_GOAL = 24 ether;
    address public admin;

    address UNISWAP_V2_FACTORY_ADDRESS = 0xc9f18c25Cfca2975d6eD18Fc63962EBd1083e978;
    address UNISWAP_V2_ROUTER_ADDRESS = 0x86dcd3293C53Cf8EFd7303B57beb2a3F671dDE98;

    uint constant DECIMALS = 10 ** 18;
    uint constant MAX_SUPPLY = 1000000 * DECIMALS;
    uint constant INIT_SUPPLY = 20 * MAX_SUPPLY / 100;

    uint256 public constant INITIAL_PRICE = 30000000000000;  // Initial price in wei (P0), 3.00 * 10^13
    uint256 public constant K = 8 * 10**15;  // Growth rate (k), scaled to avoid precision loss (0.01 * 10^18)

    event Buy(
        uint256 time,
        address indexed buyer,
        uint256 amount,
        uint256 cost
    );
    event Sell(
        uint256 time,
        address indexed seller,
        uint256 amount,
        uint256 refund
    );
    event PriceChange(uint256 time, uint256 value, uint256 marketCap);


    constructor() {
        admin = msg.sender;
    }
    // Function to calculate the cost in wei for purchasing `tokensToBuy` starting from `currentSupply`
    function calculateCost(uint256 currentSupply, uint256 tokensToBuy) public pure returns (uint256) {
        
            // Calculate the exponent parts scaled to avoid precision loss
        uint256 exponent1 = (K * (currentSupply + tokensToBuy)) / 10**18;
        uint256 exponent2 = (K * currentSupply) / 10**18;

        // Calculate e^(kx) using the exp function
        uint256 exp1 = exp(exponent1);
        uint256 exp2 = exp(exponent2);

        // Cost formula: (P0 / k) * (e^(k * (currentSupply + tokensToBuy)) - e^(k * currentSupply))
        // We use (P0 * 10^18) / k to keep the division safe from zero
        uint256 cost = (INITIAL_PRICE * 10**18 * (exp1 - exp2)) / K;  // Adjust for k scaling without dividing by zero
        return cost;
    }

    // Improved helper function to calculate e^x for larger x using a Taylor series approximation
    function exp(uint256 x) internal pure returns (uint256) {
        uint256 sum = 10**18;  // Start with 1 * 10^18 for precision
        uint256 term = 10**18;  // Initial term = 1 * 10^18
        uint256 xPower = x;  // Initial power of x
        
        for (uint256 i = 1; i <= 20; i++) {  // Increase iterations for better accuracy
            term = (term * xPower) / (i * 10**18);  // x^i / i!
            sum += term;

            // Prevent overflow and unnecessary calculations
            if (term < 1) break;
        }

        return sum;
    }

    function createMemeToken(string memory name, string memory symbol, string memory imageUrl, string memory description) public payable returns(address) {

        //should deploy the meme token, mint the initial supply to the token factory contract
        require(msg.value>= MEMETOKEN_CREATION_PLATFORM_FEE, "fee not paid for memetoken creation");
        Token ct = new Token(name, symbol, INIT_SUPPLY);
        address memeTokenAddress = address(ct);
        memeToken memory newlyCreatedToken = memeToken(name, symbol, description, imageUrl, 0, memeTokenAddress, msg.sender);
        memeTokenAddresses.push(memeTokenAddress);
        addressToMemeTokenMapping[memeTokenAddress] = newlyCreatedToken;
        return memeTokenAddress;
    }

    function getAllMemeTokens() public view returns(memeToken[] memory) {
        memeToken[] memory allTokens = new memeToken[](memeTokenAddresses.length);
        for (uint i = 0; i < memeTokenAddresses.length; i++) {
            allTokens[i] = addressToMemeTokenMapping[memeTokenAddresses[i]];
        }
        return allTokens;
    }

    function buyMemeToken(address memeTokenAddress, uint tokenQty) public payable returns(uint) {

        //check if memecoin is listed
        require(addressToMemeTokenMapping[memeTokenAddress].tokenAddress!=address(0), "Token is not listed");
        
        memeToken storage listedToken = addressToMemeTokenMapping[memeTokenAddress];

        Token memeTokenCt = Token(memeTokenAddress);

        // check to ensure funding goal is not met
        require(listedToken.fundingRaised <= MEMECOIN_FUNDING_GOAL, "Funding has already been raised");

        // check to ensure there is enough supply to facilitate the purchase
        uint currentSupply = memeTokenCt.totalSupply();
        console.log("Current supply of token is ", currentSupply);
        console.log("Max supply of token is ", MAX_SUPPLY);
        uint available_qty = MAX_SUPPLY - currentSupply;
        console.log("Qty available for purchase ",available_qty);

        uint scaled_available_qty = available_qty / DECIMALS;
        uint tokenQty_scaled = tokenQty * DECIMALS;

        require(tokenQty <= scaled_available_qty, "Not enough available supply");

        // calculate the cost for purchasing tokenQty tokens as per the exponential bonding curve formula
        uint currentSupplyScaled = (currentSupply - INIT_SUPPLY) / DECIMALS;
        uint requiredEth = calculateCost(currentSupplyScaled, tokenQty);

        console.log("ETH required for purchasing meme tokens is ",requiredEth);

        // check if user has sent correct value of eth to facilitate this purchase
        require(msg.value >= requiredEth, "Incorrect value of ETH sent");

        // Incerement the funding
        listedToken.fundingRaised+= msg.value;

        if(listedToken.fundingRaised >= MEMECOIN_FUNDING_GOAL){
            // create liquidity pool
            address pool = _createLiquidityPool(memeTokenAddress);
            console.log("Pool address ", pool);

            // provide liquidity
            uint tokenAmount = INIT_SUPPLY;
            uint ethAmount = listedToken.fundingRaised;
            uint liquidity = _provideLiquidity(memeTokenAddress, tokenAmount, ethAmount);
            console.log("Uniswap provided liquidty ", liquidity);

            // burn lp token
            _burnLpTokens(pool, liquidity);
        }

        // mint the tokens
        memeTokenCt.mint(tokenQty_scaled, msg.sender);

        console.log("User balance of the tokens is ", memeTokenCt.balanceOf(msg.sender));

        console.log("New available qty ", MAX_SUPPLY - memeTokenCt.totalSupply());

        uint256 mCap = uint256(calculateCost(currentSupplyScaled, 1)) * MAX_SUPPLY;

        emit Buy(block.timestamp, msg.sender, tokenQty_scaled, requiredEth);
        emit PriceChange(block.timestamp, uint256(calculateCost(currentSupplyScaled, 1)), mCap);

        return 1;
    }

    function sellMemeToken(address memeTokenAddress, uint tokenQty) public returns (uint) {

        // Check if the token is listed
        require(addressToMemeTokenMapping[memeTokenAddress].tokenAddress != address(0), "Token is not listed");

        memeToken storage listedToken = addressToMemeTokenMapping[memeTokenAddress];

        Token memeTokenCt = Token(memeTokenAddress);

        // Get the user's token balance to ensure they have enough to sell
        uint userBalance = memeTokenCt.balanceOf(msg.sender);
        uint tokenQty_scaled = tokenQty * DECIMALS;
        require(userBalance >= tokenQty_scaled, "Not enough tokens to sell");

        // Ensure that there's enough ETH liquidity in the contract to facilitate the sale
        uint currentSupply = memeTokenCt.totalSupply();
        uint currentSupplyScaled = (currentSupply - INIT_SUPPLY) / DECIMALS;
        uint ethToReturn = calculateCost(currentSupplyScaled - tokenQty, tokenQty); // Cost in reverse

        require(address(this).balance >= ethToReturn, "Not enough ETH in contract to facilitate the sale");

        // Burn the tokens from the user's balance
        memeTokenCt.burn(msg.sender, address(this), tokenQty_scaled);

        // Update the total funding raised to reflect the ETH being taken out
        listedToken.fundingRaised -= ethToReturn;

        // Send the ETH to the user
        (bool sent, ) = msg.sender.call{value: ethToReturn}("");
        require(sent, "Failed to send ETH to the seller");

        console.log("ETH returned to seller: ", ethToReturn);
        console.log("New available qty after sale: ", MAX_SUPPLY - memeTokenCt.totalSupply());
        
        uint256 mCap = uint256(calculateCost(currentSupplyScaled, 1)) * MAX_SUPPLY;

        emit Sell(block.timestamp, msg.sender, tokenQty_scaled, ethToReturn);
        emit PriceChange(block.timestamp, uint256(calculateCost(currentSupplyScaled, 1)), mCap);

        return 1;
    }

    function _createLiquidityPool(address memeTokenAddress) internal returns(address) {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY_ADDRESS);
        IUniswapV2Router01 router = IUniswapV2Router01(UNISWAP_V2_ROUTER_ADDRESS);
        address pair = factory.createPair(memeTokenAddress, router.WETH());
        return pair;
    }

    function _provideLiquidity(address memeTokenAddress, uint tokenAmount, uint ethAmount) internal returns(uint){
        Token memeTokenCt = Token(memeTokenAddress);
        memeTokenCt.approve(UNISWAP_V2_ROUTER_ADDRESS, tokenAmount);
        IUniswapV2Router01 router = IUniswapV2Router01(UNISWAP_V2_ROUTER_ADDRESS);
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{
            value: ethAmount
        }(memeTokenAddress, tokenAmount, tokenAmount, ethAmount, address(this), block.timestamp);
        return liquidity;
    }

    function _burnLpTokens(address pool, uint liquidity) internal returns(uint){
        IUniswapV2Pair uniswapv2pairct = IUniswapV2Pair(pool);
        uniswapv2pairct.transfer(admin, liquidity);
        console.log("Uni v2 tokens burnt");
        return 1;
    }

    function editFee(uint fee) external {
        require(msg.sender == admin, "not admin");
        MEMETOKEN_CREATION_PLATFORM_FEE = fee;
    }

    function editFundingGoal(uint fundingGoal) external {
        require(msg.sender == admin, "not admin");
        MEMECOIN_FUNDING_GOAL = fundingGoal;
    }

    function editFundingDuration(uint duration) external {
        require(msg.sender == admin, "not admin");
        MEMECOIN_FUNDING_DEADLINE_DURATION = duration ;
    }

    function editFactoryContract(address newFactory) external{
        require(msg.sender == admin, "not admin");
        UNISWAP_V2_FACTORY_ADDRESS = newFactory;
    }

        function editRouterContract(address newRouter) external{
        require(msg.sender == admin, "not admin");
        UNISWAP_V2_ROUTER_ADDRESS = newRouter;
    }
}
