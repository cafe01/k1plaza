import { Headers } from "./headers";
export declare class Request {
    method: String;
    url: String;
    headers: Headers;
    body: String;
    form: Object;
    json: Object;
    constructor(url: any, init?: any);
    toObject(): object;
}
