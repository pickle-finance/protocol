export interface TestableStrategy {
    type: string;
    name: string;
    lp_suffix: boolean;
    controller: string;
    snowglobeAddress: string;
    strategyAddress: string;
    slot: number;
    fold: boolean;
    timelockIsStrategist: boolean;
}

export const FoldTestDefault: TestableStrategy = {
    type: "FOLD",
    name: "",
    lp_suffix: false,
    controller: "main",
    snowglobeAddress: "",
    strategyAddress: "",
    slot: 0,
    fold: true,
    timelockIsStrategist: false,
}
export const SingleStakeTestDefault: TestableStrategy = {
    type: "SS",
    name: "",
    lp_suffix: true,
    controller: "main",
    snowglobeAddress: "",
    strategyAddress: "",
    slot: 0,
    fold: false,
    timelockIsStrategist: true,
}
export const LPTestDefault: TestableStrategy = {
    type: "LP",
    name: "",
    lp_suffix: true,
    controller: "main",
    snowglobeAddress: "",
    strategyAddress: "",
    slot: 0,
    fold: false,
    timelockIsStrategist: false,
}
