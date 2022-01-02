function convertToBoolean(input: string): boolean | undefined {
    try {
        return JSON.parse(input);
    }
    catch (e) {
        return undefined;
    }
}

export function log(message: string) {
    if (process.env.DEBUG && convertToBoolean(process.env.DEBUG)) {
        console.log(message);
    }
}
