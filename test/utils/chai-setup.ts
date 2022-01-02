import chaiModule from "chai";
import { solidity } from "ethereum-waffle";
import chaiRoughly from 'chai-roughly';
import chaiAsPromised from 'chai-as-promised';
chaiModule.use(solidity);
chaiModule.use(chaiAsPromised);
chaiModule.use(chaiRoughly);
export module chaiModule;
