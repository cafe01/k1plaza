export declare class Headers {
    headers: object;
    constructor(init?: object);
    append(key: string, value: string): void;
    set(key: string, value: string): void;
    get(key: any): string;
    delete(key: any): void;
    has(key: any): boolean;
    keys(): string[];
    toObject(): {};
}
