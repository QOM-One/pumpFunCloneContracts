const {expect} = require("chai");
const hre = require("hardhat");
const {time} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Token Factory", function () {
    it("Should create the meme token successfully", async function () {
        const zeroAddress = "0x0000000000000000000000000000000000000000";
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", zeroAddress, {
            value: hre.ethers.parseEther("0.0002")
        });
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    });

    it("Should revert if incorrect value of memeToken Creation fee is passed", async function () {
        const zeroAddress = "0x0000000000000000000000000000000000000000";
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        await expect(tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", zeroAddress, {
            value: hre.ethers.parseEther("0.00002")
        })).to.be.revertedWith("fee not paid for memetoken creation");
    });

    it("Should allow a user to purchase the meme token", async function() {
        const zeroAddress = "0x0000000000000000000000000000000000000000";
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", zeroAddress, {
            value: hre.ethers.parseEther("0.0002")
        });
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 800000, zeroAddress, {
            value: hre.ethers.parseEther("40")
        });
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    })
    

    it("Should allow a user to sell the meme token", async function() {
        const zeroAddress = "0x0000000000000000000000000000000000000000";
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", zeroAddress, {
            value: hre.ethers.parseEther("0.0002")
        });
        const adminAddress = await tokenCt.admin();
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 500000, zeroAddress, {
            value: hre.ethers.parseEther("15")
        });
        console.log("admin balance before sell", hre.ethers.formatEther(await hre.ethers.provider.getBalance(adminAddress)));
        const memeToken = await hre.ethers.getContractAt("Token", memeTokenAddress);
        console.log("tokens before sell",  hre.ethers.formatEther(await memeToken.balanceOf(adminAddress)));
        await tokenCt.sellMemeToken(memeTokenAddress, 500000)
        console.log("tokens after sell",  hre.ethers.formatEther(await memeToken.balanceOf(adminAddress)));
        console.log("admin balance after sell", hre.ethers.formatEther(await hre.ethers.provider.getBalance(adminAddress)));
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    })
    it("Should allow a user to buy, sell and buy all the meme tokens", async function() {
        const zeroAddress = "0x0000000000000000000000000000000000000000";
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", zeroAddress, {
            value: hre.ethers.parseEther("0.0002")
        });
        const adminAddress = await tokenCt.admin();
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 500000, zeroAddress, {
            value: hre.ethers.parseEther("15")
        });
        console.log("admin balance before sell", hre.ethers.formatEther(await hre.ethers.provider.getBalance(adminAddress)));
        const memeToken = await hre.ethers.getContractAt("Token", memeTokenAddress);
        console.log("tokens before sell",  hre.ethers.formatEther(await memeToken.balanceOf(adminAddress)));
        await tokenCt.sellMemeToken(memeTokenAddress, 500000)
        console.log("tokens after sell",  hre.ethers.formatEther(await memeToken.balanceOf(adminAddress)));
        console.log("admin balance after sell", hre.ethers.formatEther(await hre.ethers.provider.getBalance(adminAddress)));
        const tx3 = await tokenCt.buyMemeToken(memeTokenAddress, 800000, zeroAddress, {
            value: hre.ethers.parseEther("24")
        });
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    })

    it("Should allow a user to deploy and purchase a token with a referral parameter", async function() {
        const referralAddress = "0xcddeBBaD367956F2Bf3E6C668085B4884669e717";
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        console.log("referral balance before deployment", hre.ethers.formatEther(await hre.ethers.provider.getBalance(referralAddress)));
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", referralAddress, {
            value: hre.ethers.parseEther("0.0002")
        });
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 800000, referralAddress, {
            value: hre.ethers.parseEther("24")
        });
        console.log("referral balance after deployment and purchase", hre.ethers.formatEther(await hre.ethers.provider.getBalance(referralAddress)));
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    })
})