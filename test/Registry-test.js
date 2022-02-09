/* eslint-disable comma-dangle */
/* eslint-disable no-unused-expressions */
/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('Registry', async (accounts) => {
  let Registry, registry, Storage, storage;
  let admin, dev, alice, bob, charlie;

  beforeEach(async function () {
    [admin, dev, alice, bob, charlie] = await ethers.getSigners();
    const RegistryImpl = await ethers.getContractFactory('Registry');
    const registryImpl = await RegistryImpl.deploy();
    await registryImpl.deployed();
    const Proxy = await ethers.getContractFactory('TransparentUpgradeableProxy');
    const proxy = await upgrades.deploy(Proxy);
    await proxy.deployed(registryImpl.address, admin.address, []);

    Storage = await ethers.getContractFactory('Storage');
    storage = await StorageC.deploy();
    await storage.deployed();

    await registry.initRegistry();

    await registry.addProxyContract(await registry.STORAGE_NAME(), storage.address);
    await storage.initStorage('HI');
    await registry.injectDependencies(await registry.STORAGE_NAME());
  });

  before('setup', async () => {
    const contractsRegistryImpl = await ContractsRegistry.new();
    const proxy = await Proxy.new(contractsRegistryImpl.address, PROXY_ADMIN, []);
    const stbl = await STBLMock.new('stbl', 'stbl', 6);
    const _rewardsGenerator = await RewardsGenerator.new();

    contractsRegistry = await ContractsRegistry.at(proxy.address);

    await contractsRegistry.__ContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.REWARDS_GENERATOR_NAME(),
      _rewardsGenerator.address
    );

    rewardsGenerator = await RewardsGenerator.at(await contractsRegistry.getRewardsGeneratorContract());

    await rewardsGenerator.__RewardsGenerator_init();
    await contractsRegistry.injectDependencies(await contractsRegistry.REWARDS_GENERATOR_NAME());

    await reverter.snapshot();
  });

  describe('upgrade', async () => {
    it('should upgrade correctly', async () => {
      const rewardsGeneratorMock = await RewardsGeneratorMock.new();

      await contractsRegistry.upgradeContract(
        await contractsRegistry.REWARDS_GENERATOR_NAME(),
        rewardsGeneratorMock.address
      );

      rewardsGenerator = await RewardsGeneratorMock.at(await contractsRegistry.getRewardsGeneratorContract());

      await rewardsGenerator.getStake(0);

      assert.equal(
        await contractsRegistry.getImplementation.call(await contractsRegistry.REWARDS_GENERATOR_NAME()),
        rewardsGeneratorMock.address
      );
    });

    it('should upgrade and call correctly', async () => {
      const rewardsGeneratorMock = await RewardsGeneratorMock.new();

      await contractsRegistry.upgradeContractAndCall(
        await contractsRegistry.REWARDS_GENERATOR_NAME(),
        rewardsGeneratorMock.address,
        'callOnUpgrade()'
      );

      rewardsGenerator = await RewardsGeneratorMock.at(await contractsRegistry.getRewardsGeneratorContract());

      assert.equal(toBN(await rewardsGenerator.dummy()).toString(), '1337');
    });
  });

  describe('injectDependencies', async () => {
    const BMI_STBL_STAKING = accounts[6];
    const RANDOM = accounts[7];

    it('should inject dependencies correctly', async () => {
      await truffleAssert.reverts(
        rewardsGenerator.stake(RANDOM, 0, 1, { from: BMI_STBL_STAKING }),
        'RewardsGenerator: Caller is not a BMICoverStaking contract'
      );

      await contractsRegistry.addContract(await contractsRegistry.BMI_COVER_STAKING_NAME(), BMI_STBL_STAKING);

      await contractsRegistry.injectDependencies(await contractsRegistry.REWARDS_GENERATOR_NAME());

      await rewardsGenerator.stake(RANDOM, 0, 1, { from: BMI_STBL_STAKING });
    });
  });
});
