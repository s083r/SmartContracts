import Contest from '@digix/contest';
const contest = new Contest({ debug: true, timeout: 2000 });
const exchange = artifacts.require('./Exchange.sol');

contest.artifact(exchange)
	.describe('Exchange')

