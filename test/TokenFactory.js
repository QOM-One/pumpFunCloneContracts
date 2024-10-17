const {expect} = require("chai");
const hre = require("hardhat");
const {time} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Token Factory", function () {
    it("Should create the meme token successfully", async function () {
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", {
            value: hre.ethers.parseEther("0.0001")
        });
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    });

    it("Should revert if incorrect value of memeToken Creation fee is passed", async function () {
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        await expect(tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", {
            value: hre.ethers.parseEther("0.00001")
        })).to.be.revertedWith("fee not paid for memetoken creation");
    });

    it("Should allow a user to purchase the meme token", async function() {
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", {
            value: hre.ethers.parseEther("0.0001")
        });
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 800000, {
            value: hre.ethers.parseEther("40")
        });
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    })

    it("Should allow a user to sell the meme token", async function() {
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", {
            value: hre.ethers.parseEther("0.0001")
        });
        const adminAddress = await tokenCt.admin();
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 500000, {
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
    it.only("Should allow a user to buy, sell and buy all the meme tokens", async function() {
        const tokenCt = await hre.ethers.deployContract("TokenFactory");
        const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", {
            value: hre.ethers.parseEther("0.0001")
        });
        const adminAddress = await tokenCt.admin();
        const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
        const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 500000, {
            value: hre.ethers.parseEther("15")
        });
        console.log("admin balance before sell", hre.ethers.formatEther(await hre.ethers.provider.getBalance(adminAddress)));
        const memeToken = await hre.ethers.getContractAt("Token", memeTokenAddress);
        console.log("tokens before sell",  hre.ethers.formatEther(await memeToken.balanceOf(adminAddress)));
        await tokenCt.sellMemeToken(memeTokenAddress, 500000)
        console.log("tokens after sell",  hre.ethers.formatEther(await memeToken.balanceOf(adminAddress)));
        console.log("admin balance after sell", hre.ethers.formatEther(await hre.ethers.provider.getBalance(adminAddress)));
        const tx3 = await tokenCt.buyMemeToken(memeTokenAddress, 800000, {
            value: hre.ethers.parseEther("24")
        });
        const memecoins = await tokenCt.getAllMemeTokens();
        console.log("Memecoins ", memecoins)
    })
})